# Flutter Onboarding & Smart Alarm App

A premium Flutter application built as a job interview task. The app features a high-fidelity onboarding experience, location-based features, and a smart alarm system with local notifications.

## 🚀 Features

- **High-Fidelity Onboarding**: 3 beautifully designed screens with smooth transitions and progress indicators.
- **Location Sync**: Real-time location fetching using `geolocator` and address conversion via `geocoding`.
- **Smart Alarms**: 
  - Dual date and time picker.
  - Interactive alarm list.
  - Persistent storage using `shared_preferences`.
- **Local Notifications**: Scheduled notifications using `flutter_local_notifications` that trigger exactly at the set time.
- **Modern UI**: Dark mode glassmorphism design with Google Fonts (Poppins).

## 🛠️ Project Structure

The project follows a clean, feature-first architecture as requested:

```
lib/
├── common_widgets/   # Reusable UI components
├── constants/        # App-wide colors, styles, and assets
├── features/         # Feature-based modules (Onboarding, Location, Alarm)
│   ├── onboarding/
│   ├── location/
│   └── alarm/
├── helpers/          # Utility functions
├── networks/         # Network-related files
└── main.dart         # Entry point & Route configuration
```

## 📦 Packages Used

- `get`: State management and simplified navigation.
- `geolocator`: GPS location access.
- `geocoding`: Reverse geocoding (coordinates to address).
- `flutter_local_notifications`: Mobile notifications.
- `timezone`: Timezone handling for accurate scheduling.
- `intl`: Date and time formatting.
- `google_fonts`: Premium typography.
- `shared_preferences`: Local data persistence.

## ⚙️ Setup Instructions

1.  **Clone the repository**:
    ```bash
    git clone <repo-url>
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

## 📸 Screenshots
*(Add screenshots here after manual testing)*

## 🎥 Video Demo
[Loom Demo Link](https://www.loom.com/...)
