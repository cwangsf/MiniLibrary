# Excel to CSV Converter

## Purpose
This script converts `samples.xlsx` to `sample_books.csv` with proper UTF-8 encoding, fixing common text encoding issues.

## Fixed Issues
The script automatically cleans:
- Excel XML escape sequences (`_x0080__x0099_` → `'`)
- Smart quotes and apostrophes
- Em dashes and en dashes
- Special characters (®, ™, ö, ä, ß, etc.)

## Usage

### First Time Setup
```bash
# Install required library
pip3 install openpyxl
```

### Converting the Excel File
```bash
# Run from project root
python3 convert_excel_to_csv.py
```

This will:
1. Read `MiniLibrary/MiniLibrary/App/samples.xlsx`
2. Export to `MiniLibrary/MiniLibrary/App/sample_books.csv`
3. Clean all encoding artifacts
4. Save with proper UTF-8 encoding

## When to Run
Run this script whenever you:
- Update the `samples.xlsx` file
- See garbled text in book titles/authors
- Import books from a new Excel export

## Output
The script will display:
```
Loading Excel file: ...
Exporting sheet: Sheet1
Dimensions: A1:BA145
✓ Successfully exported 145 rows to: ...
✓ File saved with UTF-8 encoding
✓ Cleaned Excel XML encoding artifacts
```

## Examples of Fixed Text
| Before | After |
|--------|-------|
| `HarperCollinsChildrenâ_x0080__x0099_sBooks` | `HarperCollins Children's Books` |
| `Irelandâ_x0080__x0099_s War` | `Ireland's War` |
| `LEGOÂ® NINJAGOÂ®` | `LEGO® NINJAGO®` |
| `Voller LÃ¶cher` | `Voller Löcher` |
| `GespensterjÃ¤ger` | `Gespensterjäger` |

## Technical Details
- Uses `openpyxl` library to read Excel files
- Exports all rows from the active sheet
- Handles `None` values as empty strings
- Uses minimal CSV quoting for clean output
- Preserves all special characters correctly
