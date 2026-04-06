# E-KODI - Smart Rent & Utility Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-10.x-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> A comprehensive property management solution designed specifically for the Kenyan rental market, automating rent collection, utility bill management, and landlord-tenant communication.

## 📱 Overview

**E-Kodi** bridges the gap between landlords and tenants by digitizing property management. Landlords can manage multiple properties, track payments, and communicate with tenants through a modern Flutter app, while tenants can pay rent, check balances, and request maintenance via a simple WhatsApp bot.

### Why E-Kodi?

- **🇰🇪 Kenyan-First**: Built specifically for the Kenyan rental market with M-Pesa integration
- **📱 No App Required**: Tenants interact via WhatsApp - no downloads needed
- **💰 Revenue Assurance**: Automated tracking prevents revenue leakage
- **🚀 Real-Time**: Instant payment confirmation and receipt generation
- **🔒 Secure**: Enterprise-grade authentication and data protection

---

## ✨ Features

### For Landlords 👨‍💼
| Feature | Description |
|---------|-------------|
| 🏘️ **Property Management** | Add, edit, and manage multiple properties and units |
| 👥 **Tenant Management** | Track tenants, lease agreements, and contact details |
| 💳 **M-Pesa Integration** | Initiate STK Push payments directly to tenants |
| 💡 **Utility Billing** | Manage water, electricity, and other bills |
| 📊 **Financial Reports** | Generate revenue reports, tax summaries, and analytics |
| 📱 **Real-time Dashboard** | View occupancy rates and payment trends instantly |
| 📢 **Bulk Communication** | Send announcements via WhatsApp/SMS to all tenants |
| 📄 **Document Storage** | Store receipts, agreements, and tenant IDs securely |

### For Tenants 👨‍👩‍👧‍👦
| Feature | Description |
|---------|-------------|
| 💬 **WhatsApp Bot** | Pay rent using simple text commands |
| 💰 **Balance Inquiry** | Check outstanding balance anytime |
| 📜 **Payment History** | View all past payment records |
| 🧾 **Receipt Download** | Get payment receipts as PDF via WhatsApp |
| 🔧 **Maintenance Requests** | Report issues with photos and descriptions |
| 📢 **Announcements** | Receive important updates from landlord |
| 🔔 **Payment Reminders** | Automatic reminders before rent due date |

---

## 🛠 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Mobile App** | Flutter | 3.16+ |
| **Web Dashboard** | React + Material-UI | 18.x |
| **Backend** | Node.js + Express | 20.x |
| **Payment Service** | Python + Flask | 3.10 |
| **Database** | PostgreSQL | 14+ |
| **Real-time DB** | Firebase Firestore | Latest |
| **Authentication** | Firebase Auth | Latest |
| **Cache** | Redis | 7.x |
| **WhatsApp** | Twilio API / Evolution API | Latest |
| **M-Pesa** | Safaricom Daraja API | v1 |
| **File Storage** | Firebase Storage | Latest |

---

## 🚀 Quick Start

### Prerequisites

```bash
# Required installations
Flutter 3.16+    # flutter --version
Dart 3.2+        # dart --version  
Node.js 20+      # node --version
Python 3.10+     # python --version
PostgreSQL 14+   # psql --version
Redis 7+         # redis-server --version
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/e-kodi.git
cd e-kodi

# 2. Install Flutter dependencies
cd e_kodi
flutter pub get

# 3. Configure Firebase
flutterfire configure
# Select your Firebase project and platforms

# 4. Create environment file
cp .env.example .env
# Edit .env with your Firebase and M-Pesa credentials

# 5. Run the app
flutter run -d chrome  # Web version
# or
flutter run            # Mobile version
```

### Environment Configuration

Create a `.env` file in the project root:

```env
# Firebase Web Configuration
FIREBASE_WEB_API_KEY=your_api_key
FIREBASE_WEB_APP_ID=your_app_id
FIREBASE_PROJECT_ID=e-kodi-dashboard
FIREBASE_MESSAGING_SENDER_ID=your_sender_id

# Safaricom Daraja (M-Pesa)
DARAJA_CONSUMER_KEY=your_consumer_key
DARAJA_CONSUMER_SECRET=your_consumer_secret
DARAJA_PASSKEY=your_passkey
DARAJA_ENVIRONMENT=sandbox  # or production

# WhatsApp (Twilio)
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
WHATSAPP_NUMBER=+14155238886
```

---

## 📁 Project Structure

```
e_kodi/
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── auth_service.dart      # Firebase authentication
│   │   ├── models/                     # Data models
│   │   └── utils/                      # Helpers & validators
│   ├── features/
│   │   ├── auth/                       # Login/Register screens
│   │   ├── dashboard/                  # Main dashboard
│   │   ├── properties/                 # Property management
│   │   ├── tenants/                    # Tenant management
│   │   └── payments/                   # Payment processing
│   ├── config/
│   │   ├── routes.dart                 # Navigation routes
│   │   └── theme.dart                  # App theming
│   ├── firebase_options.dart           # Auto-generated Firebase config
│   └── main.dart                       # App entry point
├── assets/
│   ├── .env                            # Environment variables
│   └── images/                         # App assets
├── backend/
│   ├── services/                       # Backend microservices
│   └── database/
│       └── schema.sql                  # PostgreSQL schema
├── android/                            # Android-specific files
├── ios/                                # iOS-specific files
├── web/                                # Web-specific files
├── pubspec.yaml                        # Flutter dependencies
└── README.md                           # This file
```

---

## 🔐 Authentication Flow

### Registration

```dart
// Register new user
final authService = AuthService();
await authService.registerWithEmail(
  email: "landlord@example.com",
  password: "securepassword",
  fullName: "John Doe",
  phone: "+254712345678",
);
```

### Login

```dart
// Login existing user
await authService.loginWithEmail(
  email: "landlord@example.com",
  password: "securepassword",
);

// Get user data
final userData = await authService.getCurrentUserData();
print(userData['fullName']); // John Doe
```

---

## 💳 M-Pesa Integration

### STK Push Payment Flow

```javascript
// Initiate payment
POST /api/payments/initiate
{
  "tenantId": "tenant_123",
  "amount": 15000,
  "phone": "+254712345678"
}

// Response
{
  "success": true,
  "paymentId": "pay_456",
  "message": "STK Push sent to customer"
}
```

### WhatsApp Bot Commands

| Command | Description | Example |
|---------|-------------|---------|
| `pay [amount]` | Make payment | `pay 15000` |
| `balance` | Check balance | `balance` |
| `receipt [month]` | Get receipt | `receipt january` |
| `report [issue]` | Report problem | `report leaking tap` |
| `help` | Show all commands | `help` |

---

## 📊 Database Schema

### Firestore Collections

```javascript
// Users Collection
users/{userId} {
  fullName: "John Doe",
  email: "john@example.com",
  phone: "+254712345678",
  role: "landlord", // or "tenant"
  createdAt: timestamp,
  isActive: true
}

// Properties Collection
properties/{propertyId} {
  landlordId: "user_uid",
  name: "Sunset Apartments",
  location: "Kilimani, Nairobi",
  totalUnits: 20,
  occupiedUnits: 15
}

// Tenants Collection
tenants/{tenantId} {
  propertyId: "property_id",
  unitNumber: "B3",
  fullName: "Jane Smith",
  monthlyRent: 15000,
  isActive: true
}

// Payments Collection
payments/{paymentId} {
  tenantId: "tenant_id",
  amount: 15000,
  mpesaReceipt: "NFE7XQ3L9S",
  paymentDate: timestamp,
  status: "completed"
}
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📦 Building for Production

### Android APK

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build split APKs (smaller size)
flutter build apk --split-per-abi
```

### iOS App

```bash
# Build iOS archive
flutter build ios --release

# Open in Xcode for distribution
open ios/Runner.xcworkspace
```

### Web App

```bash
# Build web release
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `firebase_options.dart` not found | Run `flutterfire configure` |
| `.env` file not loading | Add `.env` to `pubspec.yaml` assets |
| M-Pesa sandbox connection failed | Ensure you're on VPN or use production keys |
| Flutter build fails | Run `flutter clean && flutter pub get` |
| Firebase Auth not working | Verify Email/Password is enabled in Firebase Console |

### Debug Mode

```bash
# Verbose logging
flutter run --verbose

# Enable debug prints
flutter run --debug

# Check Firebase logs
firebase functions:log
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

### Code Style

```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Firebase](https://firebase.google.com) - Authentication & Database
- [Safaricom](https://developer.safaricom.co.ke) - M-Pesa Daraja API
- [Twilio](https://www.twilio.com) - WhatsApp Business API
- [Flutter](https://flutter.dev) - UI Framework
- [Material Design](https://material.io) - Design System

---

## 📞 Support

| Channel | Contact |
|---------|---------|
| 📧 Email | support@ekodi.com |
| 🐛 Issues | [GitHub Issues](https://github.com/yourusername/e-kodi/issues) |
| 📖 Docs | [https://ekodi.com/docs]([https://ekodi.com/docs](https://docs.google.com/document/d/1ejuqHpE625HwqObfYUtBoWICzAWfAPjGQaJIITNYu2s/edit?usp=sharing)) |
| 💬 Twitter | [@EKodiApp](https://twitter.com/EKodiApp) |

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/e-kodi&type=Date)](https://star-history.com/#yourusername/e-kodi&Date)

---

## 🗺 Roadmap

### ✅ Completed (MVP)
- User authentication (Email/Password)
- Property management CRUD
- Tenant management
- M-Pesa STK Push integration
- WhatsApp bot with basic commands
- Payment history & receipts
- Dashboard with analytics

### 🔄 In Progress
- Advanced reporting and analytics
- Maintenance request system
- Push notifications
- Multi-language support (English/Swahili)
- Document management system

### 📅 Planned
- Tenant credit scoring
- Property listings marketplace
- Insurance integration
- AI-powered maintenance prediction
- Blockchain for lease contracts

---

**Built with ❤️ for the Kenyan rental market** 🇰🇪

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Powered by Firebase](https://img.shields.io/badge/Powered%20by-Firebase-FFCA28?logo=firebase)](https://firebase.google.com)
