# Receipt AI Analyser — Implementation Reference

> **Purpose:** This document is the single source of truth for re-implementing the AI Receipt Analyser feature after a team merge. If any files below are overwritten, follow this guide to restore the feature exactly.

---

## Feature Overview

When the user opens the **Scan tab → Receipt mode**, a live camera feed appears inside the viewfinder. The user taps the capture button, the app takes an in-app photo, sends it to **Google Gemini AI**, receives a structured JSON, and shows a pre-filled editable confirmation sheet. The user can edit any field and tap **"Add Transaction"** to save.

### Data Flow
```
User taps Capture
    ↓
CameraController.takePicture() → XFile
    ↓
GeminiReceiptService.analyseReceipt(XFile)
    ↓  sends image bytes + structured prompt
Google Gemini 2.5 Flash API
    ↓  returns raw text
_extractJson() strips markdown fences → jsonDecode()
    ↓
ReceiptParseResult (merchant, title, amount, date, category)
    ↓
ReceiptConfirmSheet (editable bottom sheet)
    ↓
onSave(Transaction tx) callback
    ↓
[TODO] provider.addTransaction(tx)  ← Firebase integration point
```

---

## 1. Environment Setup (Do This First)

### 1.1 Create `.env` file
Create a file named `.env` in the **project root** (same level as `pubspec.yaml`):
```
GEMINI_API_KEY=AIzaSyA9HxDO-fHzZmv79SH5VCIURdNCFexOI5o
```

### 1.2 Add `.env` to `.gitignore`
Append this line to `.gitignore`:
```
# Environment / secrets
.env
```

> ⚠️ **Never commit `.env` to Git.** The API key will be exposed publicly.

---

## 2. `pubspec.yaml` — New Packages

Add these 5 packages under `dependencies:` and register `.env` as a Flutter asset:

```yaml
dependencies:
  # ... existing packages ...
  image_picker: ^1.1.2
  permission_handler: ^11.3.1
  camera: ^0.11.0
  google_generative_ai: ^0.4.6
  flutter_dotenv: ^5.2.1

flutter:
  uses-material-design: true
  assets:
    - .env
```

Run after editing:
```
flutter pub get
```

---

## 3. Android Permissions — `android/app/src/main/AndroidManifest.xml`

Add these **before** the `<application>` tag:

```xml
<!-- Permissions for AI Receipt Analyser -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<!-- Fallback for Android < 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
```

---

## 4. iOS Permissions — `ios/Runner/Info.plist`

Add before the closing `</dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>SnapBudget needs camera access to scan receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SnapBudget needs photo library access to import receipts</string>
```

---

## 5. `lib/main.dart` — Load `.env` Before App Starts

Change `main()` from `void` to `Future<void>` and add `dotenv.load`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env so GeminiReceiptService can read GEMINI_API_KEY
  await dotenv.load(fileName: '.env');
  // ... rest of main unchanged ...
}
```

---

## 6. New File: `lib/models/receipt_parse_result.dart`

Pure Dart data class. **Zero Flutter/widget dependency.** Output of the Gemini service.

```dart
import 'transaction_model.dart';

class ReceiptParseResult {
  final String merchantName;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionCategory category;
  final String? customLabel;   // e.g. "Ice Cream" when category == other
  final bool parsedSuccessfully;

  const ReceiptParseResult({ ... });

  /// Returns a blank failed result (all defaults) when Gemini parsing fails.
  factory ReceiptParseResult.failed() { ... }
}
```

**Key design:** `parsedSuccessfully = false` → confirmation sheet shows a warning banner and all fields blank for manual entry.

---

## 7. Modified File: `lib/models/transaction_model.dart`

Three additions to the `Transaction` class (no breaking changes):

### 7.1 New field `customLabel`
```dart
final String? customLabel;
// Holds a free-text label when Gemini returns category "other"
// e.g. "Ice Cream", "Pet Care"
// Display this instead of category.label when non-null.
```

### 7.2 `copyWith` method
```dart
Transaction copyWith({
  String? id, String? title, String? description, double? amount,
  TransactionType? type, TransactionCategory? category, DateTime? date,
  String? merchant, PaymentMethod? paymentMethod,
  String? notes, bool? isRecurring, String? customLabel,
}) { ... }
```

### 7.3 `fromReceiptResult` factory
```dart
factory Transaction.fromReceiptResult(ReceiptParseResult result) {
  return Transaction(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: result.title,
    description: result.merchantName,
    amount: result.amount,
    type: TransactionType.expense,
    category: result.category,
    date: result.date,
    merchant: result.merchantName,
    paymentMethod: PaymentMethod.cash,
    customLabel: result.customLabel,
  );
}
```

> **Firebase integration point:** When Firebase is wired, give the transaction a Firestore document ID here instead of a timestamp ID.

---

## 8. New File: `lib/services/gemini_receipt_service.dart`

Single-responsibility service. **No Flutter widgets, no Provider, no Firebase.**

### Public API
```dart
class GeminiReceiptService {
  Future<ReceiptParseResult> analyseReceipt(XFile imageFile) async { ... }
}
```

### What it does internally
1. Reads `GEMINI_API_KEY` from `dotenv`
2. Reads image bytes from `imageFile.path`
3. Creates `GenerativeModel(model: 'gemini-2.5-flash', apiKey: key)`
4. Sends `Content.multi([DataPart(mimeType, bytes), TextPart(prompt)])`
5. Strips markdown fences from response via `_extractJson()`
6. Maps `jsonDecode()` result → `ReceiptParseResult`
7. On **any exception** → returns `ReceiptParseResult.failed()` (never crashes the app)

### Gemini Prompt Contract
The prompt explicitly asks for JSON only with these fields:
```json
{
  "merchant_name": "Swiggy",
  "total_amount": 418,
  "date": "2026-03-05",
  "title": "Dinner",
  "category": "food",
  "custom_category": null
}
```
The `category` field is constrained to exactly one of: `food, transport, shopping, entertainment, health, utilities, housing, education, travel, salary, freelance, investment, other`.

If Gemini returns an unrecognised category string, `_parseCategory()` maps it to `TransactionCategory.other` as a safe fallback.

### Debug Logging
Every step prints to the Flutter debug console with emoji prefixes:
- `🧾` — method started
- `✅` — step succeeded  
- `❌` — step failed (with the actual exception message)
- `📡` — API request sent
- `📥` — raw response received

---

## 9. New File: `lib/screens/scan/receipt_confirm_sheet.dart`

Editable modal bottom sheet. **Fully decoupled from state management.**

### Constructor
```dart
ReceiptConfirmSheet({
  required ReceiptParseResult result,
  required void Function(Transaction tx) onSave,
})
```

### Editable fields
| Field | Widget | Notes |
|-------|--------|-------|
| Title | `TextFormField` | Required |
| Merchant | `TextFormField` | Optional |
| Amount | `TextFormField` | Numeric, required |
| Date | `GestureDetector` → `showDatePicker` | |
| Category | `DropdownButtonFormField` | All 13 TransactionCategory values |
| Custom Label | `TextFormField` | Only visible when category = "other" |
| Payment Method | `DropdownButtonFormField` | UPI / Card / Cash / Net Banking / Wallet |

### `onSave` callback pattern
```dart
onSave: (Transaction tx) {
  // TODO: Replace this with provider.addTransaction(tx)
  // when the Firebase friend wires up state management.
  debugPrint('Receipt saved: ${tx.title}');
  // show success snackbar ...
}
```

> **This is the Firebase integration point for the UI layer.** The sheet itself never touches Provider or Firebase — the caller (`scan_screen.dart`) decides what to do with the transaction.

---

## 10. Modified File: `lib/screens/scan/scan_screen.dart`

The most significant change. Full rewrite of the Receipt mode.

### Mixin change
```dart
// Before:
with SingleTickerProviderStateMixin

// After:
with SingleTickerProviderStateMixin, WidgetsBindingObserver
```

### New state variables
```dart
CameraController? _cameraController;
bool _isCameraInitialized = false;
bool _isCameraPermissionDenied = false;
bool _isTorchOn = false;
bool _isProcessing = false;  // Gemini in progress
bool _isCapturing = false;   // shutter in progress
bool _showShutterFlash = false;
```

### New methods
| Method | Purpose |
|--------|---------|
| `_initCamera()` | Requests permission, picks back camera, initializes `CameraController` |
| `didChangeAppLifecycleState()` | Pauses preview on `inactive/paused`, resumes on `resumed` |
| `_captureFromCamera()` | `CameraController.takePicture()` → shutter flash → Gemini → sheet |
| `_pickFromGallery()` | `image_picker` gallery → Gemini → sheet (unchanged flow) |
| `_toggleTorch()` | `CameraController.setFlashMode(FlashMode.torch / off)` |
| `_buildCameraLayer()` | Returns `CameraPreview` / spinner / permission-denied placeholder |

### Viewfinder Stack layers (bottom → top)
```
Stack [
  Layer 1: CameraPreview (live feed, fills box)
  Layer 2: _buildScanCorners() (neon blue brackets)
  Layer 3: AnimatedBuilder scan line (horizontal blue glow)
  Layer 4: "Point at receipt" hint text (bottom of box)
]
```

### `initState` additions
```dart
WidgetsBinding.instance.addObserver(this);
WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
```

### `dispose` additions
```dart
WidgetsBinding.instance.removeObserver(this);
_cameraController?.dispose();
```

### Why `WidgetsBindingObserver`?
`MainNavScreen` uses `IndexedStack` — `ScanScreen` is **never destroyed** when switching tabs. Without the observer, the camera would keep streaming in the background, draining battery. The observer pauses the camera preview whenever the app leaves the foreground.

---

## 11. Architecture Summary

```
lib/
├── main.dart                          ← +dotenv.load()
├── models/
│   ├── transaction_model.dart         ← +customLabel, +copyWith, +fromReceiptResult
│   └── receipt_parse_result.dart      ← NEW
├── services/
│   └── gemini_receipt_service.dart    ← NEW
└── screens/
    └── scan/
        ├── scan_screen.dart           ← Full rewrite (camera + lifecycle)
        └── receipt_confirm_sheet.dart ← NEW
```

Files **not changed** at all:
- `home_screen.dart`
- `transactions_screen.dart`
- `analytics_screen.dart`
- `splitsync_screen.dart`
- `profile_screen.dart`
- `main_nav_screen.dart`
- `app_theme.dart`
- `split_bill_model.dart`

---

## 12. Firebase Integration Checklist (For the Future)

When your friend's Firebase work is merged, these are the **only two touch-points** in this feature:

1. **`lib/screens/scan/scan_screen.dart`** — in both `_captureFromCamera()` and `_pickFromGallery()`, find the `onSave` callback and change:
   ```dart
   // BEFORE (current placeholder):
   debugPrint('✅ Receipt saved: ${tx.title}...');

   // AFTER (with Firebase Provider):
   context.read<TransactionProvider>().addTransaction(tx);
   ```

2. **`lib/models/transaction_model.dart`** — in `Transaction.fromReceiptResult()`, the `id` field currently uses `DateTime.now().millisecondsSinceEpoch.toString()`. Replace with a Firestore document ID when saving to the cloud.

No other files in the receipt feature need changes for Firebase.

---

## 13. Quick Reinstall Checklist

If the feature is lost after a merge, follow these steps in order:

- [ ] Create `.env` with `GEMINI_API_KEY=...`
- [ ] Add `.env` to `.gitignore`
- [ ] Add 5 packages to `pubspec.yaml` + `assets: [.env]` → `flutter pub get`
- [ ] Add permissions to `AndroidManifest.xml`
- [ ] Add usage strings to `ios/Runner/Info.plist`
- [ ] Update `main.dart` with `await dotenv.load(fileName: '.env')`
- [ ] Create `lib/models/receipt_parse_result.dart`
- [ ] Update `lib/models/transaction_model.dart` (customLabel, copyWith, fromReceiptResult)
- [ ] Create `lib/services/gemini_receipt_service.dart`
- [ ] Create `lib/screens/scan/receipt_confirm_sheet.dart`
- [ ] Restore `lib/screens/scan/scan_screen.dart` (full rewrite)
- [ ] Run `flutter run` and test on physical device
