# ServiceMap - Local Services Marketplace

## Overview
A dual-app marketplace connecting customers with local service providers in Michigan.

## Architecture

### Customer App (iOS - Swift/SwiftUI)
- Map-based discovery of service providers
- Real-time booking and payment
- GPS tracking during service
- In-app messaging
- Review system

### Provider App (iOS - Swift/SwiftUI)
- Business profile management
- Booking management dashboard
- Route optimization
- Revenue analytics
- Customer CRM tools

### Backend (Node.js/Express)
- REST API + WebSocket for real-time features
- PostgreSQL with PostGIS for location queries
- Redis for caching and sessions
- Stripe Connect for payments/escrow
- Twilio for masked communications

### Data Scraper (Go/Python)
- Google Places API integration
- Yelp data enrichment
- Ghost mode provider population

## Revenue Model
- 10% commission on completed transactions
- 3% buyer service fee
- Optional instant payout fees (1.5-2.5%)
- Featured/promoted listings ($5-10/day)
- Service guarantee add-on ($4.99)
- Lead generation for high-ticket services

## Key Features

### Ghost Mode Strategy
- Pre-populate map with real businesses from Google Places/Yelp
- Show "Request" button for non-registered providers
- Collect request counts to identify demand
- Manual outreach to high-demand providers

### Trust & Safety
- Background checks mandatory for in-home services
- ID verification via Stripe Identity
- Video verification for providers
- Escrow payment protection (2-hour dispute window)
- Real-time GPS sharing during service

### Payment Flow
1. Customer books → Card authorized (not charged)
2. Provider completes service → Marks complete in app
3. 2-hour dispute window opens
4. Auto-release if no dispute
5. Funds transferred to provider (minus 10% commission)

## Tech Stack

**Frontend:**
- iOS: Swift 5.9+, SwiftUI, MapKit
- State Management: Combine, ObservableObject
- UI Components: Custom SwiftUI views

**Backend:**
- Runtime: Node.js 20+ with Express/Fastify
- Database: PostgreSQL 15+ with PostGIS
- Cache: Redis 7+
- Search: Elasticsearch 8+
- Queue: Bull (Redis-based)

**Third-Party Services:**
- Payments: Stripe Connect
- Maps: Google Maps Platform / Mapbox
- SMS/Calls: Twilio (masked numbers)
- Email: SendGrid
- Push: Firebase Cloud Messaging
- Background Checks: Checkr API
- ID Verification: Stripe Identity

**Infrastructure:**
- Cloud: AWS (ECS, RDS, ElastiCache)
- Container: Docker
- CI/CD: GitHub Actions
- Monitoring: DataDog, Sentry

## Project Structure
```
/workspace/ServiceMap/
├── CustomerApp/          # iOS customer application
│   └── ServiceMapCustomer/
├── ProviderApp/          # iOS provider application  
│   └── ServiceMapProvider/
├── Shared/               # Shared models, utilities
├── Backend/              # Node.js API server
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── middleware/
│   └── migrations/
└── Scraper/              # Data scraping tools
    ├── google_places.py
    └── yelp_scraper.py
```

## Getting Started

### Prerequisites
- Xcode 15+ (for iOS apps)
- Node.js 20+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose

### Environment Setup
1. Clone repository
2. Install dependencies
3. Configure environment variables
4. Run database migrations
5. Start backend server
6. Launch iOS apps in Xcode

## License
Proprietary - All rights reserved
