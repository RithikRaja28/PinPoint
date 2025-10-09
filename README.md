# PinPoint – Hyperlocal AI Marketing and Discovery Platform

**PinPoint** is an AI-powered hyperlocal marketing and discovery platform that connects small and medium businesses (SMBs) with nearby customers through real-time, location-based engagement.  
By integrating **Nokia Network-as-Code APIs** and **custom AI intelligence**, PinPoint enables intelligent geofencing, dynamic campaign creation, and AI-driven customer recommendations, transforming how offline businesses attract and retain local customers.

---

## Project Title

**PinPoint – From nearby to next-door — PinPoint connects you.**

---

## Problem

Small and medium businesses (SMBs) are crucial to local economies but face multiple operational challenges in modern customer engagement:

- Limited digital visibility compared to larger brands.
- Dependence on traditional or costly digital advertising channels.
- Lack of technical expertise for marketing automation.
- Inability to target nearby potential customers in real time.
- Absence of performance analytics and campaign intelligence.

As a result, local stores, cafes, gyms, and service providers struggle to attract nearby consumers and compete effectively in the digital ecosystem.

---

## 🧩 Proposed Solution — PinPoint

**PinPoint** bridges telecom intelligence, geolocation data, and artificial intelligence to enable **contextual marketing** and **real-time discovery** — redefining how local businesses connect with nearby customers.

---

### ⚙️ Core Capabilities

**1️⃣ AI-Powered Campaign Creation**  
Businesses can instantly design personalized campaigns and promotional content using **custom AI templates**, without any marketing expertise.

**2️⃣ Real-Time Geo-Engagement (Powered by Nokia APIs)**  
- Nokia Network-as-Code APIs enable dynamic **geofencing** and **device reachability detection**.  
- Customers receive **instant push notifications** about nearby offers as they enter an active zone.

**3️⃣ Reliable Notification Delivery**  
- If the user is **connected**, offers are sent via **push notifications**.  
- If the user is **offline or unreachable**, Nokia’s **Device Reachability API** ensures fallback delivery through **SMS**, maintaining consistent engagement even without internet connectivity.

**4️⃣ AI Local Concierge (Google Gemini API)**  
The built-in AI assistant understands natural language queries like:  
> “I have ₹300 for lunch nearby.”  
It analyzes the prompt and recommends shops that match the user’s **budget** and **category**, ranked by proximity and relevance.

---

### Design Optimization — User-Centric Geofencing

Traditional geofencing creates boundaries around **each shop**, leading to exponential complexity.  
For example:
> 100 shops × 100 users = 10,000 geofence checks.

PinPoint inverts this model to use **user-based geofencing**:
- Each **user** maintains a single geofence around their live location.  
- As the user moves, the system detects all shops within that radius.  
- This reduces complexity to **O(N)** instead of **O(N²)** — making it significantly faster, lighter, and more scalable.

---

## Nokia API Usage

| Nokia API | Function | Implementation in PinPoint |
|------------|-----------|-----------------------------|
| **Location Retrieval API** | Securely fetches real-time user location using the mobile number | Ensures precision in proximity-based targeting. |
| **Geofencing Subscription API** | Creates dynamic virtual boundaries around users or shops | Triggers promotional alerts when the user enters or exits a live zone. |
| **Device Reachability API** | Detects if the user’s device is online or connected to the network | Sends offers via push notifications when connected or via SMS if offline. |
| **Device Verification API** | Validates registered devices for authenticity | Prevents fraudulent or duplicate participation in campaigns. |

---

## Key Features — PinPoint

### 👥 Customer-Focused Features

- **User-Based Geo-Fencing:**  
  A dynamic fence is created around each user — not every shop —  
  making detection faster and scalable as users move through areas.

- **Smart Notifications:**  
  When nearby shops enter a user’s zone, they instantly receive offers  
  via push notifications or fallback SMS (using Nokia APIs).

- **AI Local Concierge:**  
  Gemini-powered AI understands queries like  
  *“I have ₹250 for lunch nearby”* and recommends the best nearby options.

- **Live Discovery Map:**  
  Explore trending shops, ongoing offers, and nearby events in real time.

- **Multi-language** support for regional inclusivity.  

### 🏪 Business Tools (Simplified for SMBs)

- **Custom AI Poster Generator:**  
  Create stunning offer posters and QR campaigns instantly.

- **Quick Campaign Setup:**  
  Define radius, budget, and timing — AI suggests the best parameters.

- **Real-Time Reach:**  
  Customers within range are notified automatically —  
  no manual setup or marketing complexity.

---
## Architecture Diagram
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/06dbeaad-45a4-4f2f-9ce7-5b2abf1de52e" />

---

## Project Structure


---
## Network API Impact in our Product

| **GeoFencing API** | **Location Retrieval & Device Connectivity API** |
|--------------------|--------------------------------------------------|
| ![GeoFencing API](https://github.com/user-attachments/assets/67bf4cc3-bf48-4b4b-b7dc-1763c6b1ffdc) | ![Location Retrieval & Connectivity](https://github.com/user-attachments/assets/4bf639f2-8908-4530-8458-80f332f7b367) |

| **Location Retrieval Response** | **Number Verification API** |
|--------------------------------|-----------------------------|
| ![Location Retrieval Response](https://github.com/user-attachments/assets/927f9612-08ba-4ef4-a93c-c74db03bc7d9) | ![WhatsApp Image 2025-10-09 at 15 17 16_73afbe9a](https://github.com/user-attachments/assets/0b49b44b-0430-4228-8f2e-59f3485f1193) |


---
## 🖼️ Product Snapshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/d521c1da-fd1d-4506-ba52-f3e85d583b8f" width="30%" />
  <img src="https://github.com/user-attachments/assets/9a1cd61e-c8fa-4dd0-9132-f9432dd21160" width="30%" />
  <img src="https://github.com/user-attachments/assets/5fe22287-a66e-4a03-b07c-48cba4f8c07f" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/c123550a-9c66-4bb0-900d-4a4c90ae2c50" width="30%" />
  <img src="https://github.com/user-attachments/assets/239745a0-a0b8-45e1-b136-604ef025cd04" width="30%" />
  <img src="https://github.com/user-attachments/assets/b3b96878-b3c9-4496-a260-72d49298bc56" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/1b2f637d-fb88-4ded-98ba-f511e2168ff8" width="45%" />
</p>

---


## 📈 Market Analysis

**PinPoint** taps into the growing hyperlocal marketing ecosystem by merging telecom data, AI, and geolocation intelligence to create a new channel of direct engagement.

- **Telecom Integration Advantage:**  
  PinPoint partners with telecom operators to deliver real-time, geofenced ads directly to users, even without explicit consent-enabling unmatched ad reach the moment nearby shops enter a user’s location zone.

- **Simplified Marketing for SMBs:**  
  Custom AI-driven poster generation and campaign management reduce marketing effort by up to 80%, allowing non-technical small and medium businesses to launch high-impact local promotions effortlessly.

- **Scalable User-Based Model:**  
  Unlike traditional systems that geofence every store, PinPoint creates dynamic fences around users, significantly reducing computational load while improving accuracy and response time.

- **High Growth Potential:**  
  With increasing smartphone penetration and demand for hyper-personalized ads, the integration of AI and network-level targeting positions PinPoint at the forefront of next-generation location marketing.

---

## Business Impact

- **Reduces marketing effort by 80%** through automation and AI content generation.  
- **Improves business reach** by enabling instant hyperlocal targeting.  
- **Enhances user engagement** with contextual offers based on geolocation and preferences.  
- **Creates new revenue channels** for telecom operators through API-based ad delivery.  
- **Prevents fraud and duplication** using device and SIM verification mechanisms.
  
---

## Tech Stack

| Layer | Technology |
|--------|------------|
| **Frontend** | Flutter (Dart), Firebase Auth, Google Maps SDK |
| **Backend** | Flask (Python), SQLAlchemy ORM |
| **AI Engine** | Google Gemini API (Natural Language Query Interpretation) |
| **Database** | PostgreSql, Firebase |
| **Telecom Integration** | Nokia Network-as-Code APIs |
| **Version Control** | Git & GitHub |

---

## Example Work Flow

1. A customer moves through a commercial area.  
2. Nokia’s **Geofencing API** detects their proximity to a shop registered on PinPoint.  
3. The system automatically sends a **personalized offer notification** through the **Device Reachability API**.  
4. The user opens the app to view details, directions, or redeemable rewards.  
5. The business gains immediate visibility and potential footfall, measurable in the analytics dashboard.  
6. The **AI Concierge** assists with queries such as:  
   “Where can I shop for clothes under ₹500 nearby?” — returning relevant businesses with pricing insights.

---

## Summary

**PinPoint** redefines local discovery and marketing by combining artificial intelligence, telecom infrastructure, and real-time location analytics.  
It empowers businesses to advertise effectively, engage customers contextually, and make data-driven decisions — all within a privacy-conscious and automated environment.

**Tagline:**  
*Every store, every street, instantly discoverable.*

---

## Future Scope

- Expansion to real-time analytics dashboards for businesses.  
- Integration with payment and redemption tracking systems.  
- Enterprise version for franchise-level marketing management.  

