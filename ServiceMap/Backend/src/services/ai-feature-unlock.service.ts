import { Pool } from 'pg';
import { AIFeatures, ProviderTier } from '../types';

/**
 * AI Feature Unlock Service
 * 
 * Manages the progressive unlocking of AI-powered features based on
 * provider activity and transaction history.
 * 
 * PHILOSOPHY:
 * - Features are unlocked by completing transactions, NOT by paying subscriptions
 * - This motivates providers to get their first booking
 * - Creates a "gamified" progression system
 * - Providers who use the platform more get more powerful tools
 * - Inactive providers (60+ days) lose advanced features but keep basic listing
 */

export class AIFeatureUnlockService {
  private db: Pool;

  constructor(db: Pool) {
    this.db = db;
  }

  /**
   * Configuration: Which features unlock at which transaction milestones
   */
  private static readonly FEATURE_MILESTONES = {
    autoInvoice: 1,           // Unlock after 1 completed job
    aiScheduler: 3,           // Unlock after 3 completed jobs
    autoBookingAgent: 5,      // Unlock after 5 completed jobs
    revenueForecast: 5,       // Unlock after 5 completed jobs
    taxAssistant: 10,         // Unlock after 10 completed jobs
    winBackCampaigns: 10,     // Unlock after 10 completed jobs
    supplyAgent: 20,          // Unlock after 20 completed jobs
    marketingAgent: 20,       // Unlock after 20 completed jobs
  };

  /**
   * Provider tier thresholds
   */
  private static readonly TIER_THRESHOLDS = {
    new: 0,                   // Just signed up
    basic: 1,                 // Completed 1 job
    active: 10,               // Completed 10 jobs
    elite: 50,                // Completed 50 jobs
  };

  /**
   * Update provider's AI features based on their transaction count
   * Call this after every completed booking
   */
  async updateProviderFeatures(providerId: string): Promise<{
    tier: ProviderTier;
    featuresUnlocked: AIFeatures;
    newlyUnlocked: string[];
  }> {
    const client = await this.db.connect();
    
    try {
      // Get current provider stats
      const result = await client.query(`
        SELECT 
          total_lifetime_transactions,
          consecutive_months_zero_transactions,
          ai_features_unlocked,
          provider_tier
        FROM provider_profiles
        WHERE id = $1
      `, [providerId]);

      if (result.rows.length === 0) {
        throw new Error('Provider not found');
      }

      const provider = result.rows[0];
      const totalJobs = provider.total_lifetime_transactions || 0;
      const currentFeatures = provider.ai_features_unlocked as AIFeatures;
      
      // Calculate new feature set
      const newFeatures: AIFeatures = {
        autoInvoice: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.autoInvoice,
        aiScheduler: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.aiScheduler,
        autoBookingAgent: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.autoBookingAgent,
        revenueForecast: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.revenueForecast,
        taxAssistant: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.taxAssistant,
        winBackCampaigns: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.winBackCampaigns,
        supplyAgent: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.supplyAgent,
        marketingAgent: totalJobs >= AIFeatureUnlockService.FEATURE_MILESTONES.marketingAgent,
      };

      // Determine which features are newly unlocked
      const newlyUnlocked: string[] = [];
      for (const [feature, unlocked] of Object.entries(newFeatures)) {
        if (unlocked && !currentFeatures[feature as keyof AIFeatures]) {
          newlyUnlocked.push(feature);
        }
      }

      // Calculate new tier
      let newTier: ProviderTier = 'new';
      if (totalJobs >= AIFeatureUnlockService.TIER_THRESHOLDS.elite) {
        newTier = 'elite';
      } else if (totalJobs >= AIFeatureUnlockService.TIER_THRESHOLDS.active) {
        newTier = 'active';
      } else if (totalJobs >= AIFeatureUnlockService.TIER_THRESHOLDS.basic) {
        newTier = 'basic';
      }

      // Check for inactivity penalty (60+ days without transactions)
      const monthsInactive = provider.consecutive_months_zero_transactions || 0;
      if (monthsInactive >= 2) {
        // Demote to basic tier, lock advanced features
        if (newTier === 'elite' || newTier === 'active') {
          newTier = 'basic';
        }
        // Keep only basic features unlocked
        newFeatures.autoInvoice = true; // Always keep invoice
        newFeatures.aiScheduler = totalJobs >= 3; // Keep if earned
        // Lock advanced features until they complete another job
        newFeatures.autoBookingAgent = false;
        newFeatures.revenueForecast = false;
        newFeatures.taxAssistant = false;
        newFeatures.winBackCampaigns = false;
        newFeatures.supplyAgent = false;
        newFeatures.marketingAgent = false;
      }

      // Update database
      await client.query(`
        UPDATE provider_profiles
        SET 
          provider_tier = $1,
          ai_features_unlocked = $2,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $3
      `, [newTier, JSON.stringify(newFeatures), providerId]);

      return {
        tier: newTier,
        featuresUnlocked: newFeatures,
        newlyUnlocked,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Record a completed transaction and update features
   * Call this when a booking status changes to 'completed'
   */
  async recordTransaction(providerId: string): Promise<{
    tier: ProviderTier;
    featuresUnlocked: AIFeatures;
    newlyUnlocked: string[];
    totalJobs: number;
  }> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Increment transaction count and reset inactivity counter
      const updateResult = await client.query(`
        UPDATE provider_profiles
        SET 
          total_lifetime_transactions = total_lifetime_transactions + 1,
          last_transaction_date = CURRENT_TIMESTAMP,
          consecutive_months_zero_transactions = 0,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
        RETURNING total_lifetime_transactions
      `, [providerId]);

      const totalJobs = updateResult.rows[0].total_lifetime_transactions;

      // Release transaction
      await client.query('COMMIT');

      // Update features (separate connection to avoid nested transaction issues)
      const featureUpdate = await this.updateProviderFeatures(providerId);

      return {
        ...featureUpdate,
        totalJobs,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  }

  /**
   * Check and apply monthly inactivity penalties
   * Run this as a cron job once per month
   */
  async applyInactivityPenalties(): Promise<{
    providersAffected: number;
  }> {
    const client = await this.db.connect();
    
    try {
      // Find providers with no transactions in the last 30 days
      const result = await client.query(`
        UPDATE provider_profiles
        SET 
          consecutive_months_zero_transactions = consecutive_months_zero_transactions + 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE 
          last_transaction_date IS NULL 
          OR last_transaction_date < NOW() - INTERVAL '30 days'
        RETURNING id, consecutive_months_zero_transactions
      `);

      let affectedCount = 0;

      // Apply penalties to providers with 2+ months of inactivity
      for (const row of result.rows) {
        if (row.consecutive_months_zero_transactions >= 2) {
          await this.updateProviderFeatures(row.id);
          affectedCount++;
        }
      }

      return {
        providersAffected: affectedCount,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Get the next milestone for a provider
   * Useful for showing progress bars and motivation messages
   */
  getNextMilestone(currentJobs: number): {
    feature: string;
    jobsNeeded: number;
    description: string;
  } | null {
    const milestones = AIFeatureUnlockService.FEATURE_MILESTONES;
    
    const entries = Object.entries(milestones).sort((a, b) => a[1] - b[1]);
    
    for (const [feature, threshold] of entries) {
      if (currentJobs < threshold) {
        return {
          feature,
          jobsNeeded: threshold - currentJobs,
          description: this.getFeatureDescription(feature),
        };
      }
    }
    
    return null; // All features unlocked
  }

  /**
   * Get human-readable description for each feature
   */
  private getFeatureDescription(feature: string): string {
    const descriptions: Record<string, string> = {
      autoInvoice: 'Auto-generate professional invoices',
      aiScheduler: 'AI-powered schedule optimization',
      autoBookingAgent: 'Let AI accept bookings automatically',
      revenueForecast: 'Predictive earnings forecasts',
      taxAssistant: 'Tax tracking and reports',
      winBackCampaigns: 'Automated customer re-engagement',
      supplyAgent: 'Smart supply ordering',
      marketingAgent: 'Auto-generate social media posts',
    };
    
    return descriptions[feature] || feature;
  }

  /**
   * Get provider's current progress toward next tier
   */
  async getProgressToNextTier(providerId: string): Promise<{
    currentTier: ProviderTier;
    currentJobs: number;
    nextTier: ProviderTier | null;
    jobsNeeded: number;
    progressPercent: number;
  }> {
    const result = await this.db.query(`
      SELECT 
        provider_tier,
        total_lifetime_transactions
      FROM provider_profiles
      WHERE id = $1
    `, [providerId]);

    if (result.rows.length === 0) {
      throw new Error('Provider not found');
    }

    const provider = result.rows[0];
    const currentTier = provider.provider_tier as ProviderTier;
    const currentJobs = provider.total_lifetime_transactions || 0;

    const tierOrder: ProviderTier[] = ['new', 'basic', 'active', 'elite'];
    const currentIndex = tierOrder.indexOf(currentTier);
    
    if (currentIndex === tierOrder.length - 1) {
      // Already at max tier
      return {
        currentTier,
        currentJobs,
        nextTier: null,
        jobsNeeded: 0,
        progressPercent: 100,
      };
    }

    const nextTier = tierOrder[currentIndex + 1];
    const jobsForNextTier = AIFeatureUnlockService.TIER_THRESHOLDS[nextTier];
    const jobsNeeded = Math.max(0, jobsForNextTier - currentJobs);
    const prevTierJobs = AIFeatureUnlockService.TIER_THRESHOLDS[currentTier];
    const progressPercent = Math.min(100, Math.round(
      ((currentJobs - prevTierJobs) / (jobsForNextTier - prevTierJobs)) * 100
    ));

    return {
      currentTier,
      currentJobs,
      nextTier,
      jobsNeeded,
      progressPercent,
    };
  }
}
