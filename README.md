# PinPoint – Hyperlocal AI Marketing and Discovery Platform

**PinPoint** is an AI-powered hyperlocal marketing and discovery platform designed to bridge the gap between small and medium businesses (SMBs) and their nearby customers. By integrating **Nokia Network-as-Code APIs** with **custom AI-driven recommendation systems**, PinPoint enables real-time, location-aware campaigns, smart notifications, and budget-based suggestions — transforming how physical businesses attract and engage with their customers.

---

## Problem

Small and medium businesses struggle to attract nearby customers due to limited visibility and technical barriers.  
Traditional marketing is either too broad or expensive, and existing platforms fail to deliver personalized, real-time engagement.  

Key challenges include:
- Lack of location-based visibility and discovery.
- Limited digital literacy among SMBs to create marketing campaigns.
- Poor targeting accuracy and campaign return.
- Absence of real-time proximity-based advertising.
- Fragmented systems for campaign creation, analytics, and customer engagement.

---

## Proposed Solution

**PinPoint** provides an integrated platform for hyperlocal marketing using AI and telecom-based intelligence.  
It allows small businesses to easily create, launch, and manage proximity-based campaigns while enabling customers to discover nearby offers dynamically.  

- Businesses can generate and publish personalized campaigns using AI tools.  
- Nokia APIs ensure live geofencing and smart notifications based on real-time movement.  
- An AI Concierge interprets user prompts like “I have ₹300 for dinner nearby” and returns relevant shop suggestions.  
- Campaigns can be triggered automatically when users enter or leave a live zone.  

This system benefits both users and SMBs — users discover local deals instantly, while businesses gain visibility without complex digital tools.

---

## Nokia API Usage

| Nokia API | Function | Application |
|------------|-----------|-------------|
| **Location Retrieval API** | Securely retrieves live user location using network-level access | Enables real-time mapping of customers without requiring the app to be active |
| **Geofencing Subscription API** | Creates dynamic virtual boundaries around the user or shop location | Triggers personalized notifications when users or shops enter or leave a fence |
| **Device Reachability API** | Detects whether a user’s device is connected or reachable | Sends push notifications when online or SMS when offline |
| **Device Verification API** | Authenticates device legitimacy | Prevents fraudulent or duplicate registrations |
| **SIM Swap Detection API** | Detects if a user’s SIM is replaced | Prevents misuse of offers by unauthorized users |

---

## Key Features

### For Businesses
- **Custom AI Poster Generator** – Automatically generates campaign creatives and QR posters.  
- **Campaign Management Console** – Allows businesses to define offer details, validity, and radius.  
- **Live Zone Boost (Geofencing)** – Promotes offers to users currently within a nearby radius.  
- **AI Deal Assistant** – Recommends optimized campaign strategies based on data analytics.  
- **Footfall & Heatmap Insights** – Visualizes real-time local traffic and engagement trends.  

### For Customers
- **Nearby Discovery Map** – Displays nearby offers and active campaigns in real time.  
- **Smart Notifications** – Sends alerts when a user enters a geofenced area with offers.  
- **AI Concierge (Gemini-powered)** – Suggests shops based on spending preferences or categories.  
- **Budget-Based Recommendations** – Understands user intent such as “I have ₹200 for coffee.”  
- **Reward & Loyalty System** – Enables earning and redeeming points across partner stores.  

---

## Market Analysis

The hyperlocal marketing and SMB enablement sector is projected to exceed **$450 billion by 2030**. Over 70% of local businesses lack digital or geolocation-based marketing capabilities.  
PinPoint uniquely addresses this gap by combining telecom-level network intelligence and AI, enabling personalized campaigns that reach users even without explicit consent or app dependency.

The product offers:
- Integration opportunities with telecom providers for carrier-level geofence targeting.
- A cost-effective marketing channel for SMBs.  
- Scalable adoption across sectors including retail, restaurants, salons, and gyms.  

This approach merges **network intelligence**, **AI automation**, and **real-time commerce**, giving PinPoint a competitive advantage in the evolving hyperlocal ecosystem.

---

## Business Impact

- Empowers small businesses with intelligent, easy-to-use marketing tools.  
- Reduces marketing effort by over **80%** through AI automation.  
- Increases local engagement and customer footfall by enabling **real-time targeting**.  
- Generates new monetization opportunities for telecom providers via network API integration.  
- Establishes trust and authenticity using device verification and SIM protection.  

---

## Architecture Diagram

            ┌───────────────────────────────────────────┐
            │          PinPoint Mobile App (Flutter)     │
            │───────────────────────────────────────────│
            │  • Customer discovery & engagement         │
            │  • Shop owner campaign management          │
            │  • AI Concierge for recommendations        │
            │  • Live map and notification interface     │
            └───────────────────────────────────────────┘
                               │
                               │  User location, campaign, and query requests
                               ▼
            ┌───────────────────────────────────────────┐
            │              Flask Backend API             │
            │───────────────────────────────────────────│
            │  • REST endpoints for shops, campaigns     │
            │  • AI request routing to Gemini            │
            │  • Integration with Nokia APIs             │
            │  • Business logic and ORM models           │
            └───────────────────────────────────────────┘
                  │                   │                   │
      ┌────────────┘                   │                   └─────────────┐
      │                                │                                 │
      ▼                                ▼                                 ▼
```
┌──────────────────────────────┐       ┌──────────────────────────────┐       ┌──────────────────────────────┐
│      MySQL / CSV Dataset     │       │      Google Gemini API       │       │    Nokia Network-as-Code     │
│──────────────────────────────│       │──────────────────────────────│       │──────────────────────────────│
│  • Shop & campaign records    │       │  • Understands user queries  │       │  • Location Retrieval API    │
│  • Average spend values       │       │  • Extracts intent           │       │  • Geofencing Subscription   │
│  • Category matching          │       │  • Generates recommendation  │       │  • Device Reachability API   │
│  • Data used for AI analysis  │       │  • Returns SQL-like output   │       │  • SIM Swap & Verification   │
└──────────────────────────────┘       └──────────────────────────────┘       └──────────────────────────────┘
           │                                      │                                      │
           │                                      │                                      │
           └──────────────────────────────────────┼──────────────────────────────────────┘
                                               │
                                               ▼
                          ┌──────────────────────────────────────────────┐
                          │         Smart Notification Engine            │
                          │──────────────────────────────────────────────│
                          │  • Triggers geofence-based alerts            │
                          │  • Sends push or SMS via reachability check  │
                          │  • Integrates with Firebase Cloud Messaging  │
                          │  • Auto-refreshes based on location changes  │
                          └──────────────────────────────────────────────┘
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────┐
                        │           User & Business Outcome            │
                        │──────────────────────────────────────────────│
                        │  • Users discover relevant local offers      │
                        │  • SMBs gain higher footfall and engagement  │
                        │  • Campaigns adjust dynamically in real-time │
                        │  • Personalized AI and network-driven reach  │
                        └──────────────────────────────────────────────┘
```
