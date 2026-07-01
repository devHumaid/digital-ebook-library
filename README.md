# Digital Ebook Library

A full-stack digital ebook library — upload, browse, search, read, download, and delete ebooks — built with a Ruby on Rails API backend and a Flutter frontend, featuring a bookshelf-style UI inspired by the classic iOS Books app.

Built as a submission for the Sagar Fab International Company Full Stack Developer assignment.

---

## 1. Project Overview

The app lets a user manage a personal ebook collection:

- Upload PDF/EPUB files with title, author, and an optional cover image
- Browse the library in a visual bookshelf layout
- Search by title, author, or file name (debounced)
- Sort by recently added, title, or author
- Read PDFs in-app with page navigation, zoom, and a page slider
- Download ebooks to the device
- Delete ebooks with a confirmation step

The backend exposes a small REST API; the Flutter app is the only client.

## 2. Tech Stack

**Backend**
- Ruby on Rails 8.1 (API-only mode)
- SQLite
- Active Storage (local disk) for file/cover uploads
- RSpec + FactoryBot for testing
- rack-cors for cross-origin requests from the Flutter app

**Frontend**
- Flutter (Dart SDK ^3.12.0)
- `provider` for state management
- `pdfx` for in-app PDF rendering
- `dio` / `http` for API calls and downloads
- `file_picker` for file/cover selection
- `flutter_test` for widget tests

## 3. Repository Structure

```
/ebook_library_backend   → Rails API
/digital_ebook_library   → Flutter app
/README.md               → this file
```

## 4. Setup Instructions

### Prerequisites
- Ruby 3.2+ and Bundler
- Node not required (API-only Rails)
- Flutter SDK (3.x) and Dart 3.12+
- A device/emulator on the same network as your machine (for physical devices) or the Android emulator / iOS simulator (which can use `localhost`/`10.0.2.2` directly)

### Clone
```bash
git clone <your-repo-url>
cd <repo-name>
```

## 5. Running the Backend

```bash
cd ebook_library_backend
bundle install
bin/rails db:create db:migrate
bin/rails server -p 3000
```

The API will be available at `http://localhost:3000`.

**Testing on a physical device?** Rails only listens on `localhost` by default, so a phone on your Wi-Fi network can't reach it. Bind to all network interfaces instead:

```bash
bin/rails server -b 0.0.0.0 -p 3000
```

You'll also need to allow inbound connections on port 3000 through your machine's firewall (Windows Defender Firewall may prompt you the first time you run this — allow it, or add a manual inbound rule if it doesn't prompt).

**Important — before running the Flutter app:** open `lib/services/api_service.dart` and check the `baseUrl` constant:

```dart
static const String baseUrl = 'http://192.168.0.105:3000';
```

- **Android emulator:** change this to `http://10.0.2.2:3000` — no need for `-b 0.0.0.0`
- **iOS simulator:** change this to `http://localhost:3000` — no need for `-b 0.0.0.0`
- **Physical device:** replace with your machine's current LAN IP (find it with `ipconfig` on Windows / `ifconfig` on Mac/Linux), make sure the device is on the same Wi-Fi network as the Rails server, and start Rails with `-b 0.0.0.0` as shown above

## 6. Running the Flutter App

```bash
cd digital_ebook_library
flutter pub get
flutter run
```

Select your target device/emulator when prompted.

## 7. Running Tests

**Backend (RSpec):**
```bash
cd ebook_library_backend
bundle exec rspec
```
Covers: model validations (title/file presence, file type, max file size), `.search` scope, listing, sorting, create/upload (success + failure paths), search endpoint, download endpoint (success + 404), and delete (success + 404).

**Frontend (Flutter widget tests):**
```bash
cd digital_ebook_library
flutter test
```
Covers: the real `LibraryScreen` across loading/loaded/empty/error states, debounced search (match, no-match, clear), the full delete confirmation flow (cancel, confirm, and failure), plus `EbookCard` and `Bookshelf` rendering.

## 8. API Overview

| Method | Endpoint                     | Description                                  |
|--------|-------------------------------|-----------------------------------------------|
| GET    | `/api/ebooks`                 | List all ebooks (`?sort=recent\|title\|author`, optional `?q=`) |
| POST   | `/api/ebooks`                 | Upload a new ebook (`title`, `author`, `file`, `cover`) |
| GET    | `/api/ebooks/:id`              | Get details for a single ebook               |
| GET    | `/api/ebooks/:id/download`     | Download the ebook file (redirects to blob)   |
| DELETE | `/api/ebooks/:id`              | Delete an ebook                               |
| GET    | `/api/ebooks/search?q=keyword` | Search by title, author, or file name         |

Suggested `config/routes.rb` (verify this matches yours):
```ruby
Rails.application.routes.draw do
  namespace :api do
    resources :ebooks, only: [:index, :show, :create, :destroy] do
      collection { get :search }
      member { get :download }
    end
  end
end
```

**Validation rules:** title required; file required; file must be `application/pdf` or `application/epub+zip`; max file size 50MB.

## 9. AI Tools Used and How

**Tools used:** Claude (primary), ChatGPT (minor problem-solving)

**How they were used:**
- Used Claude throughout development for building out screens (library, reader, upload), the bookshelf UI, and the API service/provider layer, then reviewed and adjusted the generated code myself before committing it.
- Used Claude to review the Flutter test suite and identify that the original tests (search, empty state, delete confirmation) were written against hand-built stand-in widgets instead of the real `LibraryScreen` — meaning they'd keep passing even if the real screen broke. Had Claude rewrite them as proper integration tests against the actual screen.
- Used Claude to debug a git issue where `rails new` had auto-initialized a nested `.git` repo inside `ebook_library_backend/`, which was silently blocking `git add .` from staging the backend folder at all.
- Used ChatGPT for smaller one-off issues during development (isolated syntax/debugging questions), not for larger feature or architecture work.

**AI-assisted parts:** Bookshelf UI, PDF reader screen, upload/search/delete flows, RSpec request/model specs, Flutter widget tests, README.

**Manually reviewed/changed parts:** Reviewed all generated code before committing; verified backend validations (file type, 50MB size limit) actually matched what the model enforced; confirmed API routes and request specs lined up with the real `routes.rb`.

**AI-generated code rejected or corrected:** The original Flutter test suite's search/empty-state/delete tests were rejected and rewritten — they tested disconnected placeholder widgets rather than the real screen, so passing them proved nothing about the actual app. Also caught that `EbookProvider` instantiated `ApiService()` directly with no way to inject a fake for testing, and refactored it to accept an optional injected instance.

**How AI helped with testing/debugging/architecture:** Claude's review of the provider surfaced the untestable architecture (hardcoded `ApiService()`), which led to the constructor-injection fix. Also used it to work out the emulator vs. physical-device networking difference (`10.0.2.2` vs. LAN IP vs. `-b 0.0.0.0` binding) when the app couldn't reach the local Rails server from a physical device.

## 10. Known Limitations

- EPUB files can be uploaded and downloaded but are **not rendered in-app** (only PDF reading is supported); the app shows a message directing the user to download and open EPUBs externally.
- No "last read position" persistence between sessions.
- The Flutter app's backend URL is a hardcoded constant, not runtime-configurable — must be edited per environment (see Setup Instructions above).
- Search and sort are not combinable via the UI in a single request beyond what the backend already supports server-side.
- No pagination — all ebooks load in a single request, which is fine for demo-scale libraries but wouldn't scale to a very large collection.
- No authentication/multi-user support — this is a single-user local library by design, per the assignment scope.

## 11. Manual Testing Checklist

- [x] Upload a valid PDF with title + author → appears on shelf
- [x] Upload without selecting a file → shows validation error, does not submit
- [x] Upload a file over 50MB → backend rejects with clear error message
- [x] Upload a non-PDF/EPUB file → rejected with clear error message
- [x] Search for an existing title → correct result shown
- [x] Search for a nonsense query → "No ebooks match your search" shown
- [x] Clear search → full library restored
- [x] Sort by title / author / recent → order updates correctly
- [x] Open a PDF → renders, page nav and zoom work
- [x] Download an ebook → success message shown, file present on device
- [x] Delete an ebook → confirmation dialog appears; Cancel keeps it, Delete removes it
- [x] Delete with backend offline → error shown, ebook remains in list
- [x] Empty library state → correct empty-shelf message and upload prompt shown
- [x] Kill and reopen the app → library reloads correctly from backend

## 12. Screenshots / Video

https://drive.google.com/drive/folders/1dxJJ8N46L8jLuudvApm500C1m3S0DkFZ?usp=sharing

## 13. Test Results

Screenshots of `bundle exec rspec` and `flutter test` passing are included in the same Drive folder linked above (Section 12).
