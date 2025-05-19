# Aura

**TL;DR:**  
Aura is a capstone project that delivers live, crowd-sourced updates from users at cafés. Instead of scrolling through outdated reviews, users contribute quick, structured check-ins that capture real-time info about seating availability, noise level, and overall vibe—helping others find a space that matches their needs right now.

---

## 📱 Description of Our System

**Aura** is a real-time vibe check app for cafés, built using the Flutter framework for cross-platform mobile development and Firebase for backend services. The system follows a modular structure, with each core feature organized into its own Dart file for clarity and maintainability.

### 🧱 Architecture Overview

- **Frontend:** Flutter (Dart), structured into modular screens like login, map, check-ins, profile, and settings.
- **Backend:** Firebase Authentication and Cloud Firestore for user management and data storage.
- **Maps Integration:** Google Maps API dynamically renders café markers based on real-time user check-ins.

---

## 📂 Main Features and Core Files

- `login_page.dart` / `create_account_page.dart`: Handle user sign-in and account creation.
- `map_page.dart`: Displays an interactive map with real-time café markers (green, red, gray).
- `reviews_page.dart`: Allows users to submit structured check-ins including vibe, seating, and amenities.
- `profile_page.dart`: Shows user account information (email and age).
- `past_checkins.dart`: Displays the user’s private check-in history.
- `account_page.dart` / `settings_page.dart`: Manage password and account settings.
- `upload_cafes.dart`: Admin-only tool used to seed Firestore with café metadata.
- `aura_system.dart`: Contains backend logic for streak counting, avatar leveling, and date validation.

---

## 🔁 System Flow

1. User begins at `login_page.dart` or `create_account_page.dart`.
2. After login, they land on `map_page.dart`, where they can:
   - Tap café markers to view live vibe information.
   - Submit a check-in through `reviews_page.dart`.
   - View account data in `profile_page.dart`.
   - Revisit check-in history in `past_checkins.dart`.
   - Manage settings through `settings_page.dart`.

All interactions are powered by Firebase Authentication and Firestore, with real-time UI updates managed via `setState()` and Firebase stream listeners.

---

## 🗺️ Marker & Vibe Logic

- **Green Marker:** Indicates seating is available, based on 5+ recent check-ins confirming it.
- **Red Marker:** Indicates most recent check-ins report no seating; usually grab-and-go.
- **Gray Marker:** No check-ins yet. Encourages the user to be the first to contribute.

---

## 🎮 Gamification (Streak System)

- Users earn a streak by submitting at least one check-in per calendar day.
- Avatar upgrades are unlocked at specific milestones:
  - 1–6 days: Coffee Cup  
  - 7+ days: Turtle  
  - 14+ days: Cat  
  - 30+ days: Owl

This system encourages consistent, meaningful engagement without incentivizing spam.

---

## 🛠️ Backend & Database Design

- **Firebase Authentication:** Handles account creation, secure login, and password reset.
- **Cloud Firestore:**
  - **Cafe Collection:** Each café has a document containing:
    - Name, address, hours, coordinates, Google Maps link
    - Seating report tallies to determine marker color
    - A **check-ins subcollection** with:
      - User UID  
      - Timestamp  
      - Vibes (e.g., "Cozy", "Deep Focus")  
      - Seating availability and type  
      - Noise level and crowd level  
      - Amenities (WiFi, bathrooms, power outlets)  
      - Avatar tier at check-in  
      - Metadata for streak validation
  - **User Collection:** Each user document includes:
    - Email and birthday  
    - Current streak and last check-in date  
    - Avatar level  
    - A **check-ins subcollection** for viewing private check-in history

---

## ⚙️ Optimization Notes

To avoid Firebase read/write limitations and slow performance, we limited the number of cafés stored in Firestore to the area surrounding Hunter College. This reduced cost, improved test speed, and gave us a more focused development scope.

---

## 💻 Technologies & Packages Used

**Frontend:**
- [Flutter](https://flutter.dev/) (SDK for cross-platform app development)
- [Dart](https://dart.dev/) (Programming language for Flutter)

**Backend & Services:**
- [Firebase Authentication](https://firebase.google.com/products/auth) (Secure user login)
- [Cloud Firestore](https://firebase.google.com/products/firestore) (NoSQL database for real-time data)
- [Google Maps API](https://developers.google.com/maps/documentation) (Location display and directions)

**Design & Planning:**
- [Figma](https://www.figma.com/) (UI/UX design tool)

---

## 📦 Dependencies

Make sure the following packages are included in your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.0.0
  firebase_auth: ^4.1.0
  cloud_firestore: ^4.0.0
  google_maps_flutter: ^2.1.1
  provider: ^6.0.0
  cupertino_icons: ^1.0.2
```

> Note: Versions may vary based on your Flutter SDK version.

---

## 🚀 How to Install and Run the App Locally

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-team-name/aura.git
   cd aura
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project.
   - Enable **Firebase Authentication** and **Firestore Database**.
   - Download the `google-services.json` file (for Android) and place it in `android/app/`.
   - If using iOS, set up `GoogleService-Info.plist` in Xcode.

4. **Run the app**
   ```bash
   flutter run
   ```

We ran our emulators on Chrome (option 2) to test, debug and present our app. You can do the same for simplicity sake!

---

Shoutout to our professor, Tiziana Ligorio! Thank you for this semester and for pushing us to strive for better <3
