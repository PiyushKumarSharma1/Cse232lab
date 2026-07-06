import { z } from 'zod';

// User schemas
export const UserRoleSchema = z.enum(['customer', 'provider', 'admin']);

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  phone: z.string().optional(),
  passwordHash: z.string(),
  role: UserRoleSchema,
  firstName: z.string(),
  lastName: z.string(),
  avatarUrl: z.string().optional(),
  isEmailVerified: z.boolean().default(false),
  isPhoneVerified: z.boolean().default(false),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const CreateUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  role: UserRoleSchema,
  firstName: z.string(),
  lastName: z.string(),
  phone: z.string().optional(),
});

// Provider schemas
export const ProviderStatusSchema = z.enum(['pending', 'active', 'suspended', 'inactive']);

export const ProviderProfileSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  businessName: z.string(),
  description: z.string().optional(),
  category: z.string(),
  categories: z.array(z.string()),
  serviceRadiusKm: z.number().default(25),
  latitude: z.number(),
  longitude: z.number(),
  address: z.string(),
  city: z.string(),
  state: z.string(),
  zipCode: z.string(),
  isGhost: z.boolean().default(false),
  status: ProviderStatusSchema.default('pending'),
  rating: z.number().default(0),
  reviewCount: z.number().default(0),
  completionRate: z.number().default(0),
  responseTimeMinutes: z.number().optional(),
  verified: z.boolean().default(false),
  backgroundCheckPassed: z.boolean().default(false),
  insuranceVerified: z.boolean().default(false),
  videoVerified: z.boolean().default(false),
  stripeAccountId: z.string().optional(),
  requestCount: z.number().default(0),
  totalJobs: z.number().default(0),
  totalRevenue: z.number().default(0),
  lastActiveAt: z.date().optional(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const CreateProviderProfileSchema = z.object({
  businessName: z.string(),
  description: z.string().optional(),
  category: z.string(),
  categories: z.array(z.string()).optional(),
  serviceRadiusKm: z.number().min(1).max(100).default(25),
  latitude: z.number(),
  longitude: z.number(),
  address: z.string(),
  city: z.string(),
  state: z.string(),
  zipCode: z.string(),
});

// Service schemas
export const ServiceSchema = z.object({
  id: z.string().uuid(),
  providerId: z.string().uuid(),
  name: z.string(),
  description: z.string().optional(),
  category: z.string(),
  priceType: z.enum(['fixed', 'hourly', 'range', 'quote']),
  price: z.number().optional(),
  priceMin: z.number().optional(),
  priceMax: z.number().optional(),
  duration: z.number().optional(), // in minutes
  isActive: z.boolean().default(true),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const CreateServiceSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  category: z.string(),
  priceType: z.enum(['fixed', 'hourly', 'range', 'quote']),
  price: z.number().optional(),
  priceMin: z.number().optional(),
  priceMax: z.number().optional(),
  duration: z.number().optional(),
});

// Booking schemas
export const BookingStatusSchema = z.enum([
  'pending',
  'accepted',
  'declined',
  'scheduled',
  'en_route',
  'in_progress',
  'completed',
  'disputed',
  'cancelled',
]);

export const BookingSchema = z.object({
  id: z.string().uuid(),
  customerId: z.string().uuid(),
  providerId: z.string().uuid(),
  serviceId: z.string().uuid(),
  status: BookingStatusSchema,
  scheduledAt: z.date(),
  serviceAddress: z.string(),
  serviceLatitude: z.number(),
  serviceLongitude: z.number(),
  notes: z.string().optional(),
  subtotal: z.number(),
  platformFee: z.number(),
  buyerServiceFee: z.number(),
  serviceGuaranteeFee: z.number().optional(),
  total: z.number(),
  commissionAmount: z.number(),
  paymentIntentId: z.string().optional(),
  payoutId: z.string().optional(),
  completedAt: z.date().optional(),
  disputeDeadlineAt: z.date().optional(),
  cancelledAt: z.date().optional(),
  cancelReason: z.string().optional(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const CreateBookingSchema = z.object({
  providerId: z.string().uuid(),
  serviceId: z.string().uuid(),
  scheduledAt: z.string().transform((s) => new Date(s)),
  serviceAddress: z.string(),
  serviceLatitude: z.number(),
  serviceLongitude: z.number(),
  notes: z.string().optional(),
  addServiceGuarantee: z.boolean().default(false),
});

// Review schemas
export const ReviewSchema = z.object({
  id: z.string().uuid(),
  bookingId: z.string().uuid(),
  customerId: z.string().uuid(),
  providerId: z.string().uuid(),
  rating: z.number().min(1).max(5),
  comment: z.string().optional(),
  photos: z.array(z.string()).optional(),
  isAnonymous: z.boolean().default(false),
  providerResponse: z.string().optional(),
  providerResponseAt: z.date().optional(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const CreateReviewSchema = z.object({
  bookingId: z.string().uuid(),
  rating: z.number().min(1).max(5),
  comment: z.string().optional(),
  photos: z.array(z.string()).optional(),
  isAnonymous: z.boolean().default(false),
});

// Message schemas
export const MessageSchema = z.object({
  id: z.string().uuid(),
  bookingId: z.string().uuid().optional(),
  senderId: z.string().uuid(),
  receiverId: z.string().uuid(),
  content: z.string(),
  type: z.enum(['text', 'image', 'file']).default('text'),
  mediaUrl: z.string().optional(),
  isRead: z.boolean().default(false),
  readAt: z.date().optional(),
  createdAt: z.date(),
});

export const CreateMessageSchema = z.object({
  bookingId: z.string().uuid().optional(),
  receiverId: z.string().uuid(),
  content: z.string(),
  type: z.enum(['text', 'image', 'file']).default('text'),
  mediaUrl: z.string().optional(),
});

// Export types
export type User = z.infer<typeof UserSchema>;
export type CreateUser = z.infer<typeof CreateUserSchema>;
export type ProviderProfile = z.infer<typeof ProviderProfileSchema>;
export type CreateProviderProfile = z.infer<typeof CreateProviderProfileSchema>;
export type Service = z.infer<typeof ServiceSchema>;
export type CreateService = z.infer<typeof CreateServiceSchema>;
export type Booking = z.infer<typeof BookingSchema>;
export type CreateBooking = z.infer<typeof CreateBookingSchema>;
export type Review = z.infer<typeof ReviewSchema>;
export type CreateReview = z.infer<typeof CreateReviewSchema>;
export type Message = z.infer<typeof MessageSchema>;
export type CreateMessage = z.infer<typeof CreateMessageSchema>;
export type UserRole = z.infer<typeof UserRoleSchema>;
export type ProviderStatus = z.infer<typeof ProviderStatusSchema>;
export type BookingStatus = z.infer<typeof BookingStatusSchema>;
