# MiniLibrary - Complete Project Summary

## Overview
MiniLibrary is a personal library management iOS application built with SwiftUI and SwiftData for tracking books, managing checkouts to students, and maintaining a wishlist of books to acquire.

---

## Core Features

### 1. Book Catalog Management
- **Add Books via Barcode Scanning**
  - Scan ISBN barcode using device camera
  - Automatically fetch book metadata from Google Books API
  - Show confirmation screen with book details before adding
  - Option to edit details before finalizing
  - Manual ISBN entry fallback option
  - Handle duplicate books: prompt to add more copies instead of creating duplicate entries

- **Manual Book Entry**
  - Add books without ISBN through form entry
  - Fields: Title, Author, ISBN (optional), Total Copies

- **Book Details Display**
  - Book cover image (from Google Books API)
  - Title, Author, ISBN
  - Publisher and Published Date
  - Page Count
  - Book Description (full text from Google Books)
  - Availability status (available/total copies)
  - Current checkout status with student names and due dates
  - User-editable notes field
  - **Favorite toggle** - Heart icon in toolbar to mark/unmark favorites
  - Checkout and Return buttons directly in detail view

- **Catalog View**
  - List of all books in library
  - Alphabetical sections (A-Z, plus # for non-letters)
  - Section index scroller on right side (like iOS Contacts)
  - Search functionality (by title or author)
  - Search disables sections, shows flat filtered list
  - **Language filter** - Segmented control with All/English/German options
  - **Filter by favorites** - Toggle to show only favorite books
  - Filter icon in toolbar (shows count when favorites filter is active)

- **Background Metadata Enhancement**
  - When viewing a book missing description/metadata
  - Automatically fetch from Google Books API in background
  - Update only missing fields (never overwrite existing data)
  - Preserves user data: title, author, copies, notes, checkouts
  - Silently fails if offline (no error shown to user)

### 2. Checkout System
- **Checkout Process**
  - Scan or manually enter student library ID
  - Select book to checkout
  - Set due date (default: 2 weeks from checkout)
  - Show confirmation screen before finalizing
  - Decrease available copies count
  - Create checkout record with timestamp

- **Return Process**
  - Return from Book Detail view or Return Book screen
  - **Return confirmation dialog** - Shows book cover, student info, dates before confirming
  - Display overdue warning (red badge) if past due date
  - Increase available copies count on return
  - Set return date timestamp
  - Checkout record marked as inactive (not deleted)
  - Activity log updated automatically

- **Checkout Status Tracking**
  - Active checkouts (not yet returned)
  - Overdue detection (past due date)
  - Student information linked to checkouts
  - Due date tracking

### 3. Student Management
- **Student Records**
  - Library ID (unique identifier)
  - First Name, Last Name
  - Grade level
  - Checkout history relationship

- **Student List View**
  - Display all registered students
  - Search by library ID or name
  - **Swipe to delete** students from the list
  - **Delete from Add Student view** - Existing students list with swipe-to-delete
  - Add new students via form with styled bottom button

- **Student Detail View**
  - Student information display
  - Current checkouts list
  - Checkout history

### 4. Wishlist System
- **Add to Wishlist**
  - Search Google Books by title/author
  - **Multi-select** - Select multiple books from search results
  - Checkmark UI for selected items
  - **Add X Books to Wishlist** button at bottom
  - Books marked with `isWishlistItem = true`
  - Zero copies (totalCopies = 0, availableCopies = 0)
  - Add notes about why you want the book

- **Wishlist View**
  - Separate view from catalog
  - List wishlist items with book cover images
  - **Alphabetical sections (A-Z, plus # for non-letters)**
  - **Section index scroller on right side** (like iOS Contacts)
  - **Language filter** - Segmented control with All/English/German options (includes books without language metadata)
  - **Tap book** → Opens Amazon to purchase
  - **Tap share icon** → Share book via Messages, WhatsApp, Email, etc.
  - **Swipe left** → Delete or Acquire options
  - Acquire converts wishlist item to catalog item
  - Add button in toolbar to add new wishlist items
  - No notes field (simplified workflow)

- **Wishlist Interaction**
  - Main tap: Opens Amazon search page for book
  - Share button: iOS native share sheet with formatted message and Amazon link
  - Swipe actions:
    - **Delete** (red) - Remove from wishlist
    - **Acquire** (green) - Add to catalog with copy count selection

- **Acquire Wishlist Item**
  - Confirmation sheet showing book details
  - Set number of copies to add
  - Converts wishlist item to catalog item
  - Updates: `isWishlistItem = false`, sets copy counts
  - Logs activity

### 5. Activity Log
- **Activity Types**
  - `checkout` - Book checked out to student
  - `return_book` - Book returned by student (note: value is "return_book", not "return")
  - `add_book` - Book added to catalog
  - `add_wishlist` - Book added to wishlist
  - `fulfill_wishlist` - Wishlist item acquired

- **Activity Data**
  - Timestamp (createdAt)
  - Activity type (enum)
  - Book title and author
  - Student library ID (for checkouts/returns)
  - Additional info (e.g., "2 copies")

- **Activity View**
  - Display recent activities
  - Sorted by date (newest first)
  - Icon and color coding by type
  - Formatted display with context

### 6. External Links & Sharing
- **For Catalog Books**
  - "View on Google Books" button (in BookDetailView)
  - Links to Google Books preview page
  - Uses ISBN if available, else title+author search
  - Shows reviews, ratings, preview pages

- **For Wishlist Books**
  - "Find on Amazon" button (orange, in BookDetailView)
  - Tap wishlist item → Opens Amazon directly
  - Share button (square.and.arrow.up icon) → iOS share sheet
  - Share text format: "Check out this book: "[Title]" by [Author]" + Amazon URL
  - Can share via Messages, WhatsApp, Email, Copy Link, etc.
  - Uses ISBN if available, else title+author search

### 7. Data Import & Export

#### CSV Import
- **Import Catalog from CSV**
  - Available in Add tab, Export section
  - File picker to select CSV file
  - **Fast import** - Books added instantly from CSV data
  - **Background cover fetch** - Cover images and metadata load after import completes
  - Format: ISBN, Title, Author, Total Copies, Available Copies, Language, Publisher, Published Date, Page Count, Notes
  - Required fields: Title, Author, Total Copies, Available Copies
  - Helper text shows format requirements
  - Success message shows import count
  - Activity logged for import

- **Import Wishlist from CSV**
  - File picker to select CSV file
  - Format: ISBN, Title, Author
  - Only Title is required (Author and ISBN improve search accuracy)
  - **ISBN cleaning** - Automatically removes hyphens and spaces from ISBNs
  - Handles ISBN-10 with 'X' checksum digit
  - Books added as wishlist items (0 copies)
  - Success message shows import count
  - Activity logged for wishlist import

#### CSV Export
- **Export Catalog to CSV**
  - Available in Add tab, Export section
  - Filters catalog books (excludes wishlist)
  - Exports to `library_catalog.csv`
  - Pre-generated on view load for instant sharing

- **Export Wishlist to CSV**
  - Available in Add tab, Export section
  - Filters wishlist books only
  - Exports to `library_wishlist.csv`
  - Pre-generated on view load for instant sharing

- **CSV Format** (both exports)
  - Columns: ISBN, Title, Author, Total Copies, Available Copies, Language, Publisher, Published Date, Page Count, Notes
  - Proper CSV escaping (handles commas, quotes, newlines)
  - Opens in Excel, Numbers, Google Sheets
  - Can email, save to Files, or share via any method

#### Bulk Operations
- **Delete All Data**
  - Available in Add tab, Export section (red icon)
  - Confirmation alert before deletion
  - Deletes all books, students, checkouts, and activities
  - Cannot be undone
  - Resets export files

---

## Data Models

### Book
```swift
@Model
class Book {
    var id: UUID                      // Unique identifier
    var isbn: String?                 // Optional ISBN
    var title: String                 // Required
    var author: String                // Required
    var totalCopies: Int              // Total copies owned
    var availableCopies: Int          // Currently available
    var createdAt: Date               // When added to library

    // Metadata from Google Books API
    var bookDescription: String?      // Full description
    var pageCount: Int?
    var publishedDate: String?
    var publisher: String?
    var languageCode: String?
    var coverImageURL: String?        // Thumbnail URL

    // User data
    var notes: String?                // User-editable notes
    var isWishlistItem: Bool          // Wishlist vs Catalog
    var isFavorite: Bool              // Favorite flag for filtering

    // Relationships
    var checkouts: [CheckoutRecord]?  // All checkouts (active + history)
}
```

### CheckoutRecord
```swift
@Model
class CheckoutRecord {
    var id: UUID
    var checkoutDate: Date            // When checked out
    var dueDate: Date                 // When due back
    var returnDate: Date?             // When returned (nil if active)

    // Relationships
    var book: Book?                   // Which book
    var student: Student?             // Which student

    // Computed
    var isActive: Bool                // returnDate == nil
    var isOverdue: Bool               // past dueDate and still active
}
```

### Student
```swift
@Model
class Student {
    var id: UUID
    var libraryId: String             // Unique library ID (e.g., "S12345")
    var firstName: String
    var lastName: String
    var grade: Int
    var createdAt: Date

    // Relationships
    var checkouts: [CheckoutRecord]?  // All checkouts

    // Computed
    var fullName: String              // "firstName lastName"
}
```

### Activity
```swift
@Model
class Activity {
    var id: UUID
    var createdAt: Date
    var type: ActivityType            // Enum: checkout, return_book, add_book, etc.
    var bookTitle: String
    var bookAuthor: String
    var studentLibraryId: String?     // For checkout/return
    var additionalInfo: String?       // Extra context
}

enum ActivityType: String {
    case checkout = "checkout"
    case `return` = "return_book"     // Note: backticks escape keyword
    case addBook = "add_book"
    case addWishlist = "add_wishlist"
    case fulfillWishlist = "fulfill_wishlist"
}
```

---

## Navigation Structure

### Tab-Based Navigation
1. **Catalog Tab** (book.fill icon)
   - CatalogView → BookDetailView
   - Search bar at top
   - Section index on right
   - Filter button in toolbar (favorites filter with count badge)

2. **Add Tab** (plus.circle.fill icon)
   - AddView with sections:
     - Scan Book → ScanBookView
     - Manual Entry → Manual form
     - Check Out Book → CheckoutBookView
     - Return Book → ReturnBookView
     - CSV Import/Export (Import Catalog, Import Wishlist, Export Catalog, Export Wishlist)
     - Delete All Data button

3. **Students Tab** (person.2.fill icon)
   - StudentsView → StudentDetailView
   - Add student button in toolbar

4. **Wishlist Tab** (heart.fill icon)
   - WishlistView → AcquireWishlistItemView
   - Add button in toolbar → AddWishlistItemView

5. **Activity Tab** (clock.fill icon)
   - ActivityView (list of recent activities)

---

## Key UI Components

### BookCoverImage
- Reusable component for displaying book covers
- Async image loading from URL
- Fallback placeholder with book icon
- Configurable width/height
- Shows loading state

### BookRowView
- List row component for books
- Shows cover thumbnail, title, author
- Availability badge (green if available, red if all checked out)
- Copy count display

### BarcodeScannerView
- Wraps VisionKit's DataScannerViewController
- Scans EAN13, EAN8, UPCE barcodes (ISBN formats)
- Returns scanned code via binding
- Full-screen camera view

### SectionIndexTitles
- Custom A-Z index scroller (like iOS Contacts)
- Vertical list of letters on right side
- **Larger touch targets** - 28×22pt frames for easy tapping
- **Increased font size** - 13pt semibold for readability
- Tap to jump to section
- Drag to scroll through sections
- Haptic feedback on selection
- Visual highlight on selected letter (blue circle)
- Background capsule with material effect
- Used in both CatalogView and WishlistView

### ShareSheet
- UIViewControllerRepresentable wrapper for UIActivityViewController
- iOS native share functionality
- Used for sharing wishlist book links
- Shares text + URL together

### Confirmation Views
- **CheckoutConfirmationView**: Confirm before checkout
- **ReturnConfirmationView**: Confirm before return
- **AddCopyConfirmationView**: When scanning existing book
- All show book details, relevant info, and action buttons

---

## External Services

### Google Books API
- **Base URL**: `https://www.googleapis.com/books/v1/volumes`
- **ISBN Search**: `?q=isbn:{ISBN}`
- **Title/Author Search**: `?q=intitle:{title}+inauthor:{author}&maxResults=5`
- **No API Key Required** (public API)

**Data Retrieved:**
- Title, Authors (array)
- Description (full text)
- Page Count
- Published Date
- Publisher
- Language code
- Image Links (thumbnail URL)
- Industry Identifiers (ISBN-10, ISBN-13)

**Service Implementation:**
- Actor-based BookAPIService (thread-safe)
- Async/await pattern
- Error handling for network issues
- Timeout: 10 seconds
- JSON decoding with snake_case conversion

---

## Technical Implementation Details

### SwiftData (Persistence)
- All models use `@Model` macro
- Schema includes: Book, Student, CheckoutRecord, Activity
- Relationships with delete rules
- Query with `@Query` macro
- Predicates for filtering (e.g., wishlist items)
- ModelContext for inserts/updates/deletes

### Barcode Scanning Flow
1. User taps "Scan Book"
2. Camera view opens with instructions
3. On barcode detected:
   - Check if ISBN already exists in database
   - If exists → Show "Add Copy" confirmation
   - If new → Fetch from Google Books API
4. Show confirmation screen with book details
5. Options: "Confirm & Add Book", "Edit Details", or "Cancel"
   - Cancel button at bottom returns to scanning (no toolbar "Back" button)
6. On confirm → Insert into SwiftData, log activity, dismiss

### Search Implementation
- Real-time filtering as user types
- Case-insensitive search
- Searches both title and author fields
- Uses `localizedCaseInsensitiveContains()`
- Disables sections when searching

### Availability Management
- `totalCopies`: Total books owned
- `availableCopies`: Currently available
- Checkout: `availableCopies -= 1`
- Return: `availableCopies += 1`
- Validation: `availableCopies <= totalCopies`
- Edit mode: User can manually adjust both values

### Due Date Calculation
- Default checkout period: 14 days
- Date picker allows custom due dates
- Overdue check: `Date() > dueDate && returnDate == nil`
- Visual indicators: red text/icons for overdue

---

## UI/UX Design Patterns

### Color Scheme
- Blue: Primary actions (checkout, add book, links)
- Green: Success actions (return book, confirm)
- Orange: Wishlist/Amazon links
- Red: Overdue warnings, errors
- Gray: Cancel/secondary actions

### Button Styles
- Primary: Full-width, bold text, icon + text, rounded corners (12pt)
- Secondary: Gray background, outline style
- Destructive: Red (for delete actions)
- Link buttons: Match action color with SF Symbol icons

### Card/Section Styling
- Background: `.background` (system adaptive)
- Corner radius: 12pt for cards
- Padding: 16pt standard
- Sections have headers with bold text
- Dividers between related items

### Lists
- Plain style for catalog (enables section index)
- Swipe to delete where applicable
- NavigationLink for detail navigation
- Empty state views with ContentUnavailableView

### Sheets/Modals
- Confirmation dialogs use `.sheet` with presentationDetents
- Medium detent for quick actions
- Large detent for detailed views
- NavigationStack in sheets for consistency

---

## Important Gotchas & Solutions

### 1. Scanner Blur Issue
**Problem:** Center scanning area was blurred by overlay.
**Solution:** Split instructions to top/bottom with `.black.opacity(0.6)`, use `Spacer()` for clear center area.

### 2. Book Not Saving After Scan
**Problem:** Reusing API book object directly caused persistence issues.
**Solution:** Always create fresh `Book` instance for SwiftData insertion based on current state (confirming/editing/manual).

### 3. Duplicate Book on Scan
**Problem:** After adding scanned book, "Book Already Exists" sheet appeared.
**Solution:** Call `dismiss()` instead of `viewModel.reset()` to prevent scanner from detecting same barcode again.

### 4. ActivityType enum with reserved keyword
**Problem:** Can't use `return` as enum case (Swift keyword).
**Solution:** Use backticks: `case \`return\` = "return_book"` and store as "return_book" string.

### 5. Section Index Not Showing
**Problem:** SwiftUI List doesn't always show section index automatically.
**Solution:** Created custom `SectionIndexTitles` component with `ScrollViewReader` for programmatic scrolling.

### 6. Edit Mode Data Preservation
**Problem:** Editing copies could break availability logic.
**Solution:** Validate: `totalCopies > 0`, `availableCopies >= 0`, `availableCopies <= totalCopies`. Reset to current values on invalid input.

### 7. Background Fetch Timing
**Problem:** When to fetch missing metadata?
**Solution:** On `onAppear` of BookDetailView, check if metadata missing, fetch only if needed, never overwrite existing data.

### 8. Wishlist Workflow Simplification
**Problem:** Notes field in AddWishlistItemView was unused and cluttered the UI.
**Solution:** Removed notes from wishlist add flow. Users can add notes after adding to wishlist if needed.

### 9. Multiple File Importers Conflict
**Problem:** Two `.fileImporter` modifiers on same NavigationStack caused file picker not to appear.
**Solution:** Consolidated into single `.fileImporter` with `ImportType` enum (catalog vs wishlist) to track which import to handle.

### 10. Slow CSV Import with Images
**Problem:** Fetching cover images during CSV import made it very slow (API call per book).
**Solution:** Import books instantly with CSV data only, then fetch cover images in background Task after import completes. User sees books immediately, covers load progressively.

### 11. Actor Isolation Warning (Swift 6)
**Problem:** `GoogleBooksResponse` and related structs caused "Main actor-isolated conformance" warning.
**Solution:** Added `Sendable` conformance to all API response models (GoogleBooksResponse, GoogleBookItem, VolumeInfo, etc.) to work properly across actor boundaries.

### 12. BookAPIService Decoder Isolation (Swift 6)
**Problem:** Shared `decoder` property in actor caused actor isolation warnings.
**Solution:** Marked decoder as `private nonisolated let decoder: JSONDecoder` to allow concurrent access without actor isolation.

### 13. ShareItem Binding Type Mismatch
**Problem:** WishlistItemView expected `Binding<ShareItem>` but WishlistView passed `Binding<ShareItem?>`.
**Solution:** Changed WishlistItemView to accept optional binding `@Binding var shareItem: ShareItem?` to match the `.sheet(item:)` pattern.

### 14. Section Index Jump to Wrong Position
**Problem:** Tapping letter in index scrolled to cells underneath section header instead of the section itself.
**Solution:** Moved `.id(letter)` from header Text to the Section itself, ensuring `scrollTo(letter)` scrolls to the entire section.

### 15. CSV Import Language Column Mismatch
**Problem:** CSVImporter looked for "Language" column but actual CSV file had "Languages" (plural).
**Solution:** Updated CSVImporter to check for both "Languages" and "Language" column names, trying plural first then falling back to singular.

### 16. Language Filter Not Matching Books
**Problem:** Language filter looking for "en"/"de" codes but CSV data contained full words like "English"/"German".
**Solution:** Enhanced filter logic to check multiple patterns: exact code match (`"en"`), full word (`"english"`), and substring match (`.contains("english")`), all case-insensitive.

### 17. Wishlist Books Missing from Language Filter
**Problem:** Wishlist books imported from simple CSV don't have language metadata, so language filters showed very few books.
**Solution:** Added `includeUnknown` parameter to `LanguageFilter.filter()` method. Set to `true` for WishlistView so books without language data still appear in all filter modes.

---

## File Structure

```
MiniLibrary/
├── Models/
│   ├── Book.swift
│   ├── Student.swift
│   ├── CheckoutRecord.swift
│   ├── Activity.swift
│   └── Language.swift (enum)
│
├── Views/
│   ├── CatalogView.swift
│   ├── BookDetailView.swift
│   ├── AddView.swift
│   ├── StudentsView.swift
│   ├── StudentDetailView.swift
│   ├── WishlistView.swift
│   ├── ActivityView.swift
│   ├── CheckoutBookView.swift
│   ├── ReturnBookView.swift
│   ├── ScanBookView.swift
│   ├── AddWishlistItemView.swift
│   └── AcquireWishlistItemView.swift
│
├── Views/Components/
│   ├── BookCoverImage.swift
│   ├── BookRowView.swift
│   ├── WishlistItemView.swift
│   ├── BarcodeScannerView.swift
│   ├── CheckoutConfirmationView.swift
│   ├── ReturnConfirmationView.swift
│   ├── AddCopyConfirmationView.swift (in ScanBookView.swift)
│   ├── SectionIndexTitles.swift
│   ├── LanguageFilterPicker.swift (LanguageFilter enum + picker view)
│   └── ShareSheet.swift (in WishlistView.swift)
│
├── ViewModels/
│   └── ScanBookViewModel.swift
│
├── Services/
│   ├── BookAPIService.swift (actor-based, includes cover image fetching and caching)
│   ├── CSVExporter.swift (enum with static methods)
│   ├── CSVImporter.swift (struct with ISBN cleaning)
│   └── CSVParser.swift
│
└── MiniLibraryApp.swift (main entry point)
```

---

## Android Migration Considerations

### SwiftUI → Jetpack Compose Equivalents
- `@Model` → Room Database entities
- `@Query` → Room DAO queries with Flow
- `@State` → `remember { mutableStateOf() }`
- `@Environment` → Dependency injection (Hilt)
- `NavigationStack` → NavController
- `List` → LazyColumn
- `Sheet` → ModalBottomSheet or Dialog
- `Task { }` → coroutines with `viewModelScope.launch`
- `@Observable` → ViewModel with StateFlow

### Camera/Barcode Scanning
- Use CameraX + ML Kit Barcode Scanning
- Similar flow: Camera preview → detect barcode → fetch info

### Network Layer
- Retrofit + OkHttp for Google Books API
- Gson or Moshi for JSON parsing
- Same endpoints and data structure

### UI Components to Build
- Custom section index scroller (RecyclerView with FastScroller)
- Book cover image with Coil (like AsyncImage)
- Card layouts with Material Design 3
- Tab navigation with BottomNavigationBar
- Search bar with Material SearchView

### Key Android-Specific Changes
- Use Material 3 color scheme and components
- Follow Android navigation patterns
- Handle back button properly
- Use ViewModels for state management
- Implement proper lifecycle awareness
- Consider tablet/foldable layouts
- Use WorkManager for background tasks
- Handle permissions (camera, internet)

---

## Testing Checklist

### Books
- [ ] Scan ISBN barcode successfully
- [ ] Fetch book info from Google Books
- [ ] Show confirmation before adding (three buttons: Confirm, Edit, Cancel)
- [ ] Cancel button at bottom returns to scanning (no toolbar Back button)
- [ ] Edit book details before adding
- [ ] Manual book entry works
- [ ] Handle duplicate ISBN (add copy prompt)
- [ ] Background fetch updates missing metadata
- [ ] Description displays correctly
- [ ] Cover images load properly
- [ ] Edit availability counts with validation
- [ ] Notes save correctly

### Checkouts
- [ ] Checkout reduces available copies
- [ ] Confirmation screen shows before checkout
- [ ] Due date defaults to 14 days
- [ ] Custom due date works
- [ ] Return increases available copies
- [ ] Return confirmation shows overdue warning
- [ ] Activity logged for checkout/return
- [ ] Multiple checkouts per book work
- [ ] Checkout history preserved after return

### Students
- [ ] Add student with library ID
- [ ] View student details
- [ ] See student's checkouts
- [ ] Delete student works
- [ ] Search students by ID/name

### Wishlist
- [ ] Search and add to wishlist
- [ ] Multi-select books from search results
- [ ] Checkmark UI shows selected items
- [ ] Add X Books button works with multiple selections
- [ ] Wishlist items show with 0 copies and book covers
- [ ] A-Z sections display correctly
- [ ] Section index scrolls to letter
- [ ] Tap wishlist item opens Amazon
- [ ] Share button opens iOS share sheet
- [ ] Share text includes formatted message and Amazon URL
- [ ] Swipe left shows Delete and Acquire actions
- [ ] Acquire converts to catalog item
- [ ] Delete removes from wishlist
- [ ] Add button in toolbar works
- [ ] Language filter segmented control appears in wishlist
- [ ] "All" language filter shows all wishlist books (including those without language metadata)
- [ ] "English" language filter includes books without metadata
- [ ] "German" language filter includes books without metadata
- [ ] Language filter preserves A-Z sections

### Catalog & Favorites
- [ ] A-Z sections display correctly
- [ ] Section index scrolls to letter
- [ ] Search filters books
- [ ] Search disables sections
- [ ] Empty states show properly
- [ ] Google Books link works for catalog items
- [ ] Favorite toggle in book detail works
- [ ] Favorites filter in catalog works
- [ ] Favorites filter shows count badge
- [ ] Filtered favorites list displays correctly
- [ ] Language filter segmented control appears in catalog
- [ ] "All" language filter shows all books
- [ ] "English" language filter shows only English books
- [ ] "German" language filter shows only German books
- [ ] Language filter works correctly with search
- [ ] Language filter preserves sections

### Activity Log
- [ ] All activity types recorded
- [ ] Sorted by newest first
- [ ] Icons and colors correct
- [ ] Detailed info displayed

### Import & Export
- [ ] Import Catalog from CSV works
- [ ] Import Wishlist from CSV works
- [ ] ISBN cleaning removes hyphens and spaces
- [ ] ISBN-10 with 'X' checksum handled correctly
- [ ] Import file picker appears correctly
- [ ] Books import instantly (fast)
- [ ] Cover images load in background after import
- [ ] Import success message shows count
- [ ] Activity logged for imports
- [ ] Export Catalog to CSV works
- [ ] Export Wishlist to CSV works
- [ ] CSV files have correct filenames
- [ ] CSV format is valid (opens in Excel/Numbers)
- [ ] Pre-generation completes on view load
- [ ] Share sheet works for both exports
- [ ] Catalog export excludes wishlist items
- [ ] Wishlist export only includes wishlist items
- [ ] Delete All Data works with confirmation
- [ ] Delete All Data removes everything correctly

---

## Future Enhancement Ideas

### Features to Consider
1. **Multi-user support** - Different libraries/classes
2. **Email notifications** - Overdue book reminders
3. **Barcode generation** - Print library ID cards
4. **Statistics** - Most popular books, checkout trends
5. **Photo attachments** - Damage documentation
6. **Fine tracking** - Overdue fines calculation
7. **Reservation system** - Reserve checked-out books
8. **Categories/genres** - Organize books by type
9. **Reading level** - Lexile/AR level tracking
10. **Series tracking** - Group books in series
11. **Bulk edit operations** - Batch edit selected books
12. **Offline mode** - Queue actions when offline
13. **Dark mode** - Explicit theme toggle
14. **Additional languages** - Expand beyond current 4 languages (EN, DE, GA, ZH-Hans)
15. **QR codes** - Alternative to barcodes for custom items
16. **Book recommendations** - Suggest similar books
17. **Notes with rich text** - Formatting support in notes
18. **Checked out books view** - Dedicated view showing all current checkouts with overdue highlighting

---

## Development Notes

### Xcode Project Setup
- Deployment target: iOS 17.0+
- SwiftUI + SwiftData
- Enable camera usage in Info.plist
- VisionKit framework for barcode scanning

### Dependencies
- No third-party dependencies (all native iOS frameworks)
- VisionKit (barcode scanning)
- SwiftData (persistence)
- SwiftUI (UI framework)

### Localization
- **Supported Languages**: 4 languages
  - English (en) - Source language
  - German (de) - Deutsch
  - Irish (ga) - Gaeilge
  - Simplified Chinese (zh-Hans) - 简体中文
- **Implementation**: Localizable.xcstrings catalog
- **Coverage**: All major UI strings are localized
- **Dynamic Language Switching**: Follows iOS system language settings

### Build Configuration
- Bundle identifier: com.yourcompany.minilibrary
- Version: 1.0
- Build number: Increment for each release

### App Store Considerations
- SKU: Unique identifier for App Store Connect
- Privacy policy: Data storage (local only, no cloud)
- Camera permission: "To scan book barcodes"
- Screenshots: Required for all device sizes
- App description: Focus on personal library management

---

## Summary

MiniLibrary is a complete library management solution with:
- ✅ Book catalog with barcode scanning and A-Z index
- ✅ Student checkout/return system with confirmations
- ✅ Wishlist management with Amazon integration
- ✅ Activity logging for all operations
- ✅ External links (Google Books, Amazon)
- ✅ Social sharing for wishlist books
- ✅ **CSV import & export** (catalog and wishlist separately)
- ✅ Rich metadata from Google Books API
- ✅ Background metadata enhancement
- ✅ **Favorites system** with filtering
- ✅ **Bulk data operations** (delete all, import CSV)
- ✅ Intuitive iOS-native UI with haptic feedback
- ✅ **Multi-language support** (English, German, Irish, Chinese)
- ✅ Offline-capable with background enhancements
- ✅ No external dependencies

**Recent Updates (Post-Initial Release):**
- Added A-Z section index scroller in catalog (like iOS Contacts)
- **Added A-Z section index scroller in wishlist** (like catalog)
- **Increased section index size** - Larger touch targets (28×22pt) and font (13pt)
- Added book cover images to wishlist view
- Wishlist tap now opens Amazon directly
- Added share button for wishlist items (iOS share sheet)
- **Multi-select wishlist** - Select multiple books from search results to add
- Added CSV export for both catalog and wishlist
- **Added CSV import** for catalog and wishlist with background cover fetching
- **ISBN cleaning in CSV import** - Automatically removes hyphens and spaces
- **Added favorites system** - Mark books as favorites and filter catalog view
- **Added return confirmation dialogs** from checked out books list
- **Added swipe-to-delete** for students
- **Added Delete All Data** feature with confirmation
- Removed unused notes field from wishlist add screen
- Improved external links in BookDetailView
- Fixed multiple file importer conflict issue
- **Fixed Swift 6 actor isolation warnings** - BookAPIService decoder, Sendable conformance
- **Fixed ShareItem binding** - Changed to optional binding in WishlistItemView
- **Fixed section index scrolling** - Moved .id() to Section instead of header
- **Added language filter** - Segmented control in Catalog and Wishlist views (All/English/German)
- **Created LanguageFilterPicker component** - Reusable language filter with enum-based filtering
- **Enhanced CSV import** - Supports both "Language" and "Languages" column names
- **Improved scan book confirmation flow** - Removed toolbar "Back" button, added "Cancel" button at bottom of confirmation screen

The app follows iOS design patterns, uses modern SwiftUI/SwiftData, and provides a complete workflow for managing a personal or classroom library. All core features are implemented and tested.

For Android migration, focus on equivalent technologies (Room, Compose, CameraX, Retrofit) while maintaining the same feature set and user flow.

---

## Code Quality & Refactoring (October 2025)

### Refactoring Summary

Comprehensive code refactoring was performed to improve maintainability, reduce duplication, and establish reusable patterns throughout the codebase.

### A. View Modifier Refactoring

**1. Button Styles** - `ProminentButtonStyle.swift`
- **Created reusable button modifiers:**
  - `.prominentButton(color:fullWidth:)` - Colored buttons with white text, rounded corners
  - `.secondaryButton(fullWidth:)` - Gray background buttons
- **Replaced verbose styling** - Reduced 8+ lines of button styling to 1 line
- **Files updated**: 6 files (ScanBookView, ReturnConfirmationView, CheckoutConfirmationView, BookDetailView, AddWishlistItemView, AcquireWishlistItemView)

**2. Text Styles** - `TextStyles.swift`
- **Created semantic text modifiers:**
  - `.sectionTitle()` - Title2, bold
  - `.labelStyle()` - Caption, secondary
  - `.bookTitle()` - Headline, centered
  - `.bookAuthor()` - Subheadline, secondary
  - `.valueText()` - Headline
  - `.badge(backgroundColor:foregroundColor:)` - Caption2, bold with background
- **Files updated**: 4 files (ReturnConfirmationView, CheckoutConfirmationView, ScanBookView, AcquireWishlistItemView)

**3. Icon Styles** - `IconStyles.swift`
- **Created icon style modifiers:**
  - `.iconStyle(color:)` - Standard colored icon
  - `.smallIcon(color:)` - Caption2 sized icon
  - `.largeIcon(color:size:)` - Large decorative icon (default 60pt)
  - Semantic styles: `.personIcon()`, `.calendarIcon()`, `.successIcon()`, `.warningIcon()`, `.errorIcon()`
- **Files updated**: 5 files (ReturnConfirmationView, CheckoutConfirmationView, ScanBookView, AcquireWishlistItemView, CheckedOutBooksListView)

### B. Service Layer Extraction

**1. BookManagementService.swift**
- **Purpose**: Centralize book management operations
- **Methods:**
  - `returnBook(_:modelContext:)` - Handles book returns with activity logging
- **Eliminated duplication**: Removed identical `returnBook()` logic from 4 files
- **Files updated**: BookDetailView, CheckedOutBooksListView, ReturnBookView, ScanBookView

**2. ActivityLogger.swift**
- **Purpose**: Centralize all activity logging operations
- **Methods (10 total):**
  - Book: `logBookAdded(_:copies:)`, `logCopiesAdded(_:copies:)`
  - Checkout: `logCheckout(_:student:dueDate:)`, `logReturn(_:studentLibraryId:)`
  - Wishlist: `logWishlistAdded(_:)`, `logWishlistAddedManually(_:)`, `logWishlistBulkAdd(count:)`, `logWishlistFulfilled(_:copies:)`
  - CSV Import: `logCatalogCSVImport(count:)`, `logWishlistCSVImport(count:)`
- **Eliminated duplication**: Removed ~70 lines of duplicate Activity creation code from 7 files
- **Type-safe**: Specialized methods prevent logging errors
- **Files updated**: BookManagementService, CheckoutBookView, ScanBookView (2 locations), AcquireWishlistItemView, AddWishlistItemView (2 locations), AddBookView, AddView (2 locations)

### C. Model Extensions

**1. Book URL Generation** - `Book.swift` extension
- **Methods added:**
  - `googleBooksURL()` - Generates Google Books search URL
  - `amazonURL()` - Generates Amazon search URL
  - Both use ISBN when available, fallback to title + author
- **Eliminated duplication**: Removed 32 lines of duplicate URL generation from 2 files
- **More semantic API**: `book.amazonURL()` vs `generateAmazonURL(for: book)`
- **Files updated**: BookDetailView, WishlistItemView

### D. Utility Components

**1. AlphabeticalGrouping.swift**
- **Purpose**: Reusable alphabetical grouping for any type
- **Components:**
  - `AlphabeticalGrouping<T>` - Result struct with grouped dictionary and sorted section titles
  - `AlphabeticalGrouper` - Static grouping utility using KeyPath
- **Features:**
  - Generic implementation works with any type
  - Groups by first letter (A-Z) with "#" for non-letters
  - Automatically moves "#" to end of sorted list
- **Eliminated duplication**: Removed 46 lines of duplicate grouping logic from 2 files
- **Files updated**: CatalogView, WishlistView

**2. ScannerCornerBrackets.swift**
- **Purpose**: Reusable barcode scanner overlay component
- **Components:**
  - `ScannerCornerBrackets` - Main view with customizable color, length, thickness
  - `CornerBracket` - Private helper for individual corners
- **Eliminated duplication**: Removed 80+ lines of repetitive corner bracket code
- **Customizable**: Easy to change appearance without touching complex layout code
- **Reduced file size**: ScanBookView reduced from 790 lines to 686 lines (104 lines removed)

### E. UI Improvements

**1. Add Tab Reorganization** - `AddView.swift`
- **"Scan Book Barcode" made prominent:**
  - Moved to separate "Quick Actions" section at top
  - Larger icon (32pt) with descriptive subtitle
  - "Add, check out, or return books instantly" description
  - Extra padding for visual separation
- **Better organization:**
  - "Quick Actions" - Scan Book Barcode
  - "Add Items" - Manual book/wishlist/student entry
  - "Manage Checkouts" - Check out/Return books
  - "Export" - CSV Import/Export and bulk operations

**2. Language Filter UI** - `CatalogView.swift` & `WishlistView.swift`
- **Improved placement**: Moved from awkward Section/EmptyView pattern to `.safeAreaInset`
- **Better visual separation**: Uses `.ultraThinMaterial` background
- **Consistent implementation**: Same pattern in both Catalog and Wishlist views

### F. Architecture Benefits

**Overall Impact:**
- **DRY Principle**: Eliminated ~200+ lines of duplicate code across the codebase
- **Single Source of Truth**: Changes to common patterns only need to be made once
- **Type Safety**: Specialized methods and components prevent errors
- **Maintainability**: Easier to find and update common functionality
- **Testability**: Isolated components and services are easier to unit test
- **Consistency**: Same patterns and styles used throughout the app
- **Readability**: View code is cleaner and easier to understand
- **Reusability**: Components can be used in new features without modification

### G. Updated File Structure

```
MiniLibrary/
├── Models/
│   ├── Book.swift (+ URL generation extension)
│   └── ...
│
├── Views/Components/
│   ├── ProminentButtonStyle.swift (NEW)
│   ├── TextStyles.swift (NEW)
│   ├── IconStyles.swift (NEW)
│   ├── ScannerCornerBrackets.swift (NEW)
│   └── ...
│
├── Services/
│   ├── BookManagementService.swift (NEW)
│   ├── ActivityLogger.swift (NEW)
│   └── ...
│
├── Utilities/
│   ├── AlphabeticalGrouping.swift (NEW)
│   └── ...
```

### H. Code Metrics

**Lines of Code Reduced:**
- Button/Text/Icon styling: ~150 lines eliminated
- Activity logging: ~70 lines eliminated
- URL generation: ~32 lines eliminated
- Alphabetical grouping: ~46 lines eliminated
- Scanner corner brackets: ~80 lines eliminated
- **Total: ~378 lines of duplicate code removed**

**Files Refactored:**
- View modifiers: 15 files updated
- Services: 7 files updated
- Utilities: 2 files updated
- **Total: 24 files improved**

**New Reusable Components Created:**
- 7 new files (ProminentButtonStyle, TextStyles, IconStyles, ScannerCornerBrackets, BookManagementService, ActivityLogger, AlphabeticalGrouping)
- All documented with clear purpose and usage examples
- All type-safe and generic where appropriate
