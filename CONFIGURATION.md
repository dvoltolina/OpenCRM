# Configuration

Create your own Firebase project and register the apps you intend to run. Enable the required Auth providers, Firestore, Storage, and Functions for your installation. Client Firebase configuration is public at runtime; service account keys and provider secrets belong only on the server.

## CRM and Admin

Run `npm ci` in each app folder. Copy `.env.example` to `.env.local` and fill the `VITE_FIREBASE_*` values from your Firebase app registration. Optional integrations have additional variables in the examples. Vite exposes `VITE_*` values to the browser; never put server secrets in those variables. Demo mode requires your own separate project and seeded synthetic data.

## Flutter

From `The Scheduler/`:

```sh
flutter pub get
cp .env.firebase.example .env.firebase.local
# Fill the FIREBASE_* values for your own registered apps.
flutter run -d chrome --dart-define-from-file=.env.firebase.local
```

`lib/firebase_options.dart` reads build values and refuses to initialize an unconfigured project. Native builds also require your own `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`; these filenames are ignored by Git. Register matching Android application and iOS bundle identifiers. Set your own Apple signing team and OAuth URL schemes in Xcode. Desktop Firebase configuration may require additional platform setup.

If using FlutterFire CLI, direct generated Dart output to the ignored `lib/firebase_options.local.dart`, and copy the relevant client values into your local build configuration. Do not replace the checked-in environment-based options with credentials.

To enable the standalone public booking page, copy `web/firebase-config.example.js` to `web/firebase-config.js` and fill your client Firebase settings. The local file is ignored. Serve that directory over HTTP during development.

## Shared backend

The authoritative backend is `The Scheduler/functions/`. Run `npm ci` and `npm run build` there. Use `functions/.env.example` to identify required provider settings and configure server secrets in your deployment environment. Keep service account files outside the source tree; use application default credentials where available.

From `The Scheduler/`, copy `.firebaserc.example` to `.firebaserc` and select your own project. Review `firebase.json`, Firestore rules/indexes, Storage rules, authentication providers, CORS origins, return URLs, and each enabled integration before deploying. Use explicit project selection with the Firebase CLI. Deploy the shared backend from this folder only.

The Admin and CRM backend snapshots are historical/reference code. Do not deploy them as a competing backend. Seed scripts write data; point them only at a project and tenant you own, and use synthetic data.

## Optional Python services

Create a Python virtual environment for the service you need under `The Scheduler/ai_server/` and install its `requirements.txt`. Copy its environment example locally and configure authentication, allowed origins, and provider endpoints. No hosted model or inference service is supplied.

## Public release hygiene

Keep local `.env` files, Firebase native registrations, signing files, service accounts, build output, and private logs out of Git. Run the public-file check and Gitleaks before pushing. If a real credential has been exposed elsewhere, rotate it in the relevant provider; removing it from this release cannot revoke it.
