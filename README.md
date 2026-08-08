# Flutter Bonus Assignment - Rashad Muntasir Hamid - 2210122 - Section 1

CSE464 Summer 2026 — Firebase Firestore CRUD with the Coffee Records app.

---

## What this project does

The base classroom app kept coffee records in a plain `List` in memory, so
everything vanished on restart. This version puts Firestore behind it:

- Records are written to a `coffee_records` collection in Cloud Firestore.
- A new screen reads that collection **live** using `snapshots()` inside a
  `StreamBuilder`, so changes appear without a manual refresh.
- Records can be edited and deleted straight from the list.
- The original local-list screen is still there, with a button to pull a
  one-time snapshot from Firebase.

---

## Before you run it — 3 things you must do

The code is complete, but it points at a Firebase project that does not exist
yet. Do these first.

### 1. Create the Firebase project and enable Firestore

1. Go to <https://console.firebase.google.com> and click **Add project**.
2. Name it something like `cse464-coffee-2210122`. Google Analytics is optional.
3. In the left sidebar open **Build → Firestore Database → Create database**.
4. Pick **Start in test mode** and any region (`asia-south1` is closest to Dhaka).

### 2. Connect Firebase to this Flutter app

From the project root, run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your project, tick **android** and **web** (add iOS/macOS if you need
them), and let it finish. This **overwrites `lib/firebase_options.dart`** with
your real keys and drops `android/app/google-services.json` into place.

> The `firebase_options.dart` currently in the repo is a placeholder full of
> `REPLACE_ME_...` strings. The app compiles with it but will throw on startup
> until `flutterfire configure` replaces it.

If `flutterfire` is not found, add pub's bin folder to your PATH:
`export PATH="$PATH":"$HOME/.pub-cache/bin"`

### 3. Set the Firestore rules

In the console open **Firestore Database → Rules**, paste the contents of
[`firestore.rules`](firestore.rules), and click **Publish**. The core of it is:

```
allow read, write: if true;
```

This is wide open on purpose — it is what the assignment asks for. It is not
safe for anything real.

### Then run

```bash
flutter pub get
flutter run
```

---

## Where each requirement lives

| Requirement | File |
|---|---|
| Firebase initialised at startup | `lib/main.dart` |
| Firebase config | `lib/firebase_options.dart` |
| Firestore rules | `firestore.rules` |
| Quicktype data model | `lib/models/coffee_records_model.dart` |
| Firestore CRUD + streams | `lib/state_management/coffee_state_management.dart` |
| Send data to Firebase | `lib/screens/create_coffee_record_screen.dart` |
| New screen: snapshots + StreamBuilder | `lib/screens/firebase_coffee_records_screen.dart` |
| Local list + one-time fetch | `lib/screens/coffe_records_screen.dart` |
| Collection name constant | `lib/utility/constant.dart` |

---

## The data model

Generated on <https://quicktype.io> from this sample document, then extended by
hand (the extra bits are commented in the file):

```json
{
  "id": 1754654321000000,
  "title": "Cappuccino",
  "des": "Morning cup from the campus cafe",
  "amount": 180.0,
  "date": "2026-08-08T09:15:00.000Z"
}
```

Quicktype gives you `fromJson` / `toJson`. Three additions were needed for
Firestore:

- **`docId`** — Firestore's auto-generated document id, needed for update and
  delete. It is null until a record has been written or read back.
- **`copyWith`** — used to attach the `docId` after `.add()` returns it.
- **A tolerant date parser** — dates are stored as ISO-8601 strings, but the
  parser also accepts epoch milliseconds and Firestore `Timestamp` objects so
  documents typed by hand in the console still load.

---

## What's in `CoffeeStateManagement`

Still a `ChangeNotifier` used through Provider, now with `FirebaseFirestore`
inside it:

**Read (real time)**
- `coffeeRecordsSnapshots` — raw `Stream<QuerySnapshot>`, newest first. This is
  what the `StreamBuilder` consumes.
- `coffeeRecordsStream` — the same stream mapped to `List<CoffeeRecordsModel>`.

**Read (one time)**
- `fetchCoffeeRecordsOnce()` — a single `.get()` that refills the local `items`.

**Create**
- `sendCoffeeRecordToFirebase(record)` — `.add()`, then writes the returned id
  back into the document. Returns the id, or null on failure.
- `createCoffeeRecord(...)` — builds the model from form values and sends it.

**Update**
- `updateCoffeeRecord(record)` — full overwrite, keyed on `docId`.
- `updateCoffeeRecordFields(...)` — partial update of only the changed fields.

**Delete**
- `deleteCoffeeRecord(docId)`

**State flags**
- `isSaving` — true while a write is in flight; the save button shows a spinner
  and stops responding to taps.
- `errorMessage` — last failure, surfaced in a SnackBar rather than swallowed.

---

## How the StreamBuilder screen works

`lib/screens/firebase_coffee_records_screen.dart` handles all four states:

1. **Waiting** — `CircularProgressIndicator`.
2. **Error** — an explanation plus a hint to check the rules and the config file.
3. **Empty** — a prompt to add the first record, not a blank screen.
4. **Data** — a `ListView.builder` of cards, each with edit and delete buttons.

Each document is converted with
`CoffeeRecordsModel.fromJson(doc.data()).copyWith(docId: doc.id)`.

Editing opens a bottom sheet with the same validators as the create form.
Deleting asks for confirmation first.

---

## Testing that it actually works

1. Add a record in the app → it appears in the Firebase console under
   `coffee_records`.
2. Edit a field directly in the console → the app list updates on its own, no
   refresh. This is the part that proves the stream is live.
3. Delete from the app → the document disappears from the console.
4. Kill and reopen the app → records are still there.

---

## Fixes to the base code along the way

- `coffe_records_screen.dart` had
  `Provider.of<CoffeeStateManagement>(...) as Provider<CoffeeStateManagement>`,
  which throws a cast error at runtime. `Provider.of` already returns the value,
  so the cast and the wrong field type were removed.
- `create_coffee_record_screen.dart` created its `TextEditingController`s inside
  `build()` of a `StatelessWidget`, so they were rebuilt constantly and never
  disposed. It is now a `StatefulWidget` with proper `dispose()`.
- Removed a redundant `setState({})` that fought with `notifyListeners()`.

---

## Notes

- `minSdk` is raised to 23 and `multiDexEnabled` turned on in
  `android/app/build.gradle.kts`, both required by the Firebase SDK.
- `INTERNET` permission added to the main `AndroidManifest.xml`.
- `google-services.json` is not committed — run `flutterfire configure` to
  generate your own.
- The stock counter widget test was replaced with real unit tests for the
  validators and the model (`test/widget_test.dart`). Run them with
  `flutter test` — no emulator or Firebase connection needed.

### One gotcha with `.gitignore`

The repo's `.gitignore` (inherited from the base project) already contains:

```
firebase_options.dart
android/app/google-services.json
```

So after you run `flutterfire configure`, **your generated config will not be
committed**, and whoever clones the repo gets a project that does not build
until they configure their own Firebase. That is the secure default and it is
usually what you want.

If your instructor needs the config committed so they can run the app as-is,
force-add it:

```bash
git add -f lib/firebase_options.dart android/app/google-services.json
```

Only do this because the assignment rules are already fully open
(`allow read, write: if true`), so there is nothing left to protect. Never do it
on a real project.
