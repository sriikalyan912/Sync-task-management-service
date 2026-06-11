# Expense Tracker (Flutter)

A mobile expense tracker with daily spending graphs, UPI QR scan-and-pay
tracking, and fully local SQLite storage.

## Features

- **Expense management** — add, edit, and delete expenses with amount,
  title, category, date, payment method (Cash / UPI / Card), and notes.
- **Dashboard** — monthly and daily totals, transaction count, and the
  full history grouped by day.
- **Graphs** — a bar chart of your spending for **every day** over the
  last 7 / 30 / 90 days, plus a category-wise pie chart breakdown with
  totals, daily average, and highest-spend day.
- **UPI QR scan & pay** — scan any UPI QR code (Google Pay, PhonePe,
  Paytm, BHIM, merchant QRs, ...). The app parses the `upi://pay` link,
  lets you confirm the amount and category, redirects you to your
  installed UPI app to complete the payment, and then records the
  transaction (payee name, VPA, reference) as an expense.
- **Local SQLite database** — every category and expense is stored in
  `expense_tracker.db` on the device via `sqflite`. No network, no cloud;
  your data never leaves the phone.

## Project structure

```
lib/
  main.dart                     # App entry point + theming
  models/                       # Expense & category models
  db/database_helper.dart       # SQLite schema, seeding, CRUD
  providers/expense_provider.dart  # State + daily/category aggregations
  screens/
    root_screen.dart            # Bottom navigation + scan FAB
    home_screen.dart            # Dashboard + grouped history
    add_expense_screen.dart     # Add / edit expense form
    stats_screen.dart           # Daily bar chart + category pie chart
    qr_scanner_screen.dart      # UPI QR camera scanner
    upi_payment_screen.dart     # Confirm, launch UPI app, record payment
  utils/
    upi_parser.dart             # upi://pay deep-link parsing/building
    formatters.dart             # ₹ currency & date formatting
  widgets/expense_tile.dart     # Swipe-to-delete expense list tile
```

## Database schema

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,        -- icon key, mapped to Material icons in code
  color INTEGER NOT NULL
);

CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  date TEXT NOT NULL,        -- ISO-8601
  payment_method TEXT NOT NULL DEFAULT 'cash',
  payee_vpa TEXT,            -- UPI payee address (from scanned QR)
  payee_name TEXT,
  txn_ref TEXT,
  note TEXT
);
```

## How the UPI flow works

1. Tap the QR button and point the camera at a UPI QR code.
2. The QR payload (`upi://pay?pa=...&pn=...&am=...`) is parsed; invalid /
   non-UPI codes are rejected.
3. Confirm the amount (locked if the QR fixes it) and pick a category.
4. "Pay with UPI app" launches the `upi://pay` deep link, so Android shows
   your installed UPI apps (or opens the default one).
5. When you return to the tracker, confirm whether the payment succeeded —
   if yes, it is saved to the local database with the payee details.

> Note: UPI deep links do not return a verified payment status to the
> calling app (that requires a PSP/merchant API), so the app asks you to
> confirm before recording. There is also an "Already paid — just record
> it" shortcut for payments made directly from another app.

## Getting started

```bash
cd expense_tracker
flutter pub get
flutter run            # Android device/emulator recommended
```

Run the tests:

```bash
flutter test
```

### Android

Everything is preconfigured: camera permission, the Android 11+
`<queries>` declaration for discovering UPI apps, and `minSdk 21`.

### iOS

Generate the iOS scaffolding, then add the camera and UPI permissions:

```bash
flutter create --platforms=ios .
```

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to scan UPI QR codes.</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>upi</string>
</array>
```
