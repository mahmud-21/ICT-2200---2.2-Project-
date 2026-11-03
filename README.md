# The Abstract of my app 
~~~
Krishi Bazar is a Bengali-first application that brings vegetable market information and an AI image-recognition workflow into one interface. The project uses Flutter and Dart for the client, Cloud Firestore for market records, Firebase Authentication for administrator sign-in, and the Gemini API for image analysis. The supplied in-terface demonstrates searchable market listings, district filters, wholesale and retail prices, camera or gallery input, vegetable-based price comparison, and an adminis-trative price-entry form. The design also supports presenting vegetable information in Bengali. This report explains the architecture, data model, technologies, secu-rity considerations, and evaluation plan. Application screenshots document interface implementation, but they do not establish recognition accuracy, response time, na-tionwide data coverage, or production readiness. Future work includes a labelled recognition dataset, controlled end-to-end tests, protected AI credentials, and veri-fied market-data integration.

Keywords: Bengali interface, vegetable recognition, market prices, Flutter, Firebase, Gemini API.
~~~
# কৃষি বাজার (Krishi Bazar) — Flutter starter project

This is a runnable starter project for a Bengali-first vegetable market-price app.

## Included
- Home screen with Bengali UI and market price cards
- Search by vegetable or market
- Camera/gallery image selection and image preview
- Admin form for adding vegetable market-price records
- Firestore data model/service
- Demo prices when Firebase is not configured

## Important limitations
This is a **starter implementation**, not yet a production-ready app.
1. The displayed sample prices are fictional demo data. Do not present them as live/current prices.
2. AI vegetable recognition requires a Gemini API key at launch/build time.
3. The admin screen does not authenticate an administrator yet. Do not publish it until Firebase Authentication and Firestore security rules restrict writes to trusted admins.
4. No official LivePrice API is assumed. Confirm API availability and permission before connecting any third-party data source.
5. Firebase initialization needs your project's configuration. Never commit service-account credentials or API secrets.

## Requirements
- Flutter SDK installed
- Android Studio / Android SDK
- A Firebase project (optional for demo mode, required for cloud storage)

## Run the app with Gemini recognition

The local API key is kept in `.secrets/gemini-api-key.json` and excluded from
version control. Start the app from VS Code using the `Krishi Bazar` launch
configuration, or pass the file explicitly:

```bash
flutter pub get
flutter run --dart-define-from-file=.secrets/gemini-api-key.json
```

Build a release APK with recognition enabled using:

```bash
flutter build apk --release --dart-define-from-file=.secrets/gemini-api-key.json
```

If Firebase isn't configured, the app attempts to show demo prices. Firebase
may emit a setup message in the debug console.

## Connect Firebase
Recommended route:
1. Install Firebase CLI and FlutterFire CLI.
2. Create a Firebase project in the Firebase Console.
3. In the project folder, run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Replace the basic initialization in `lib/main.dart` with the generated configuration:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
   and add `import 'firebase_options.dart';`.
5. Enable Cloud Firestore. Create a `market_prices` collection.
6. Add documents with fields matching `MarketPrice.toMap()`:
   - `vegetableId` (string)
   - `vegetableName` (string)
   - `marketName` (string)
   - `district` (string)
   - `wholesalePrice` (number)
   - `retailPrice` (number)
   - `unit` (string, e.g. `কেজি`)
   - `updatedAt` (ISO date string)
   - `source` (string)

## Security before release
Do not leave public write access enabled. Add Firebase Authentication and assign an admin role securely. Restrict Firestore writes using security rules. A hidden admin button is not security.

## Add AI vegetable recognition safely
Use a Firebase Cloud Function or secure backend:
1. Flutter uploads the chosen image to Firebase Storage.
2. Backend validates the file type/size and calls the chosen image-recognition model using a secret stored on the server.
3. Backend returns a structured vegetable name and confidence.
4. Flutter searches Firestore for that vegetable and displays market prices.
Never commit an AI API key. A key passed to a Flutter client is still extractable
from the built app; restrict it in Google AI Studio/Google Cloud and use a
trusted backend for production deployments.

## Build checklist
- [ ] Configure Firebase
- [ ] Add secure admin sign-in/authorization
- [ ] Add Firestore rules and test them
- [ ] Connect AI recognition through a backend
- [ ] Add edit/delete price records
- [ ] Add price update history and data-source timestamps
- [ ] Test on a real Android phone
- [ ] Verify all price data before publishing
