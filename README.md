# 📱 Campus Social

A modern social media application built with Flutter. This app allows users to share posts, send messages, and interact with friends in real-time within a campus community.

## 🚀 Features
- **User Authentication**
  - Sign up, login, and two-factor authentication
  - Password reset and account recovery
  - Social media login options
- **Posts & Stories**
  - Create posts with image/video upload
  - Share stories that disappear after 24 hours
  - Like, comment, and save functionality
  - Explore trending posts
- **Profiles & Connections**
  - Customizable user profiles
  - Follow/unfollow mechanism
  - View followers and following lists
  - Block unwanted users
- **Messaging & Notifications**
  - Real-time chat with WebSockets
  - Push notifications for activities
  - Message read receipts
  - Media sharing in conversations
- **Advanced Features**
  - Archive posts and stories
  - Dark/Light mode support
  - Post analytics
  - Content discovery algorithm
  - Offline capabilities with local caching

## 📸 Screenshots  
<p align="center">
  <img src="https://github.com/user-attachments/assets/e2a04e58-8684-4f03-b760-1f8a69d5ceef" width="200" alt="Login Screen">
  <img src="https://github.com/user-attachments/assets/14754ed4-5400-46f7-bbb9-6717491c0e0c" width="200" alt="Home Feed">
  <img src="https://github.com/user-attachments/assets/69f12329-5ff3-4b2c-bc02-8c9ec73732e9" width="200" alt="Profile Screen">
  <img src="https://github.com/user-attachments/assets/69d75e7c-b090-448b-a3a9-35d20f7da59d" width="200" alt="Story View">
  <img src="https://github.com/user-attachments/assets/fe846a86-f4b6-45e6-a3e6-8bc7ca1dfa8a" width="200" alt="Post Creation">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/81313f8f-b994-469f-9b61-299e7a8fe945" width="200" alt="Explore Page">
  <img src="https://github.com/user-attachments/assets/9a9eccc9-01f9-4d18-a859-7551b648ea8b" width="200" alt="Messages">
  <img src="https://github.com/user-attachments/assets/fc4f3716-e6f4-4383-80e1-5f5bfa7c0e65" width="200" alt="Chat Screen">
  <img src="https://github.com/user-attachments/assets/d78db962-a7c8-449a-b020-13a5a8f85e9c" width="200" alt="Notifications">
  <img src="https://github.com/user-attachments/assets/28f84706-6dc6-4e7c-bd10-8cc57757b15d" width="200" alt="Settings">
</p>

## 🔧 Tech Stack
- **Frontend**: Flutter/Dart
- **State Management**: Provider, Riverpod, Bloc
- **Routing**: Go Router
- **Networking**: Dio, Retrofit, WebSockets
- **Database**: Firebase Firestore, SQLite, Hive
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Notifications**: Firebase Messaging, Local Notifications
- **Media**: Image Picker, Video Player, Camera

## 📦 Installation

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Firebase project (for backend services)

### Setup Steps
1. **Clone the Repository**
   ```bash
   git clone https://github.com/YusufAkin27/social_media.git
   cd campus-social
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download and place the configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the App**
   ```bash
   flutter run
   ```

## 🧪 Testing
```bash
flutter test
```

## 🔍 Project Structure
```
lib/
├── components/      # Reusable UI components
├── enums/           # Enumeration types
├── models/          # Data models
├── routes/          # App navigation
├── screens/         # App screens
├── services/        # API and backend services
├── widgets/         # Common widgets
└── main.dart        # Entry point
```

## 🛠️ Development
- **Code Generation**: This project uses code generation for JSON serialization and API clients.
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

- **Adding New Features**: Follow the existing architecture pattern
  - Create models in the models directory
  - Add services in the services directory
  - Create UI components in components or widgets
  - Add screens in the screens directory

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact
For any inquiries or support, please reach out at ysufakn63@gmail.com
