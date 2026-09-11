# Udaet architecture

## Direction

Udaet is a local-first KDE Plasma diary application. The UI is QML/Kirigami and
the application and persistence logic is C++/Qt. The first target is KDE Plasma
on Wayland, while avoiding Wayland-specific APIs in the domain layer.

The application is intentionally split into four boundaries:

- **Presentation:** Kirigami pages, models, and actions in QML.
- **Application services:** C++ use cases such as loading a day, saving an
  entry, importing images, calculating trends, and exporting a date range.
- **Persistence:** SQLite accessed through Qt SQL. Database migrations are
  versioned and run before the application services use the database.
- **Files:** A managed application-data directory contains copied image assets
  and generated exports. Original image paths are never required after import.

## Initial data model

- `days`: one row per local calendar day, with an optional rating stored as a
  decimal value constrained to `0.00..10.00`.
- `entries`: one editable Markdown document per day.
- `attachments`: copied image files associated with a day, including MIME type,
  display order, and a stable content identifier.
- `metrics`: extensible optional numeric values per day, reserved for future
  feelings and other daily measurements.

The day is the aggregate root. This preserves one entry per day now while
allowing additional metrics and attachments without changing the diary entry
format.

## Markdown and images

Markdown is the source format, never a WYSIWYG document. The editor will show
source and rendered preview side by side. Imported PNG, JPEG, and WebP files
are copied into managed storage; the gallery remains usable if the original
file is later deleted.

The renderer is kept behind an application service interface. This permits a
small Qt-compatible Markdown implementation for the first release and avoids
making the persistence model depend on a particular preview technology.

## Export

Exports operate on presets (day, week, month, year, all time) and arbitrary
date ranges. The first format is self-contained HTML with images embedded or
bundled into the generated artifact. Markdown remains an internal source
format and is not the user-facing export contract.

## Architecture decision

C++/Qt 6/Kirigami is the preferred implementation for this project. Compared
with cxx-qt, it has fewer language-boundary and packaging concerns for a
Kirigami-first desktop application and aligns directly with KDE Frameworks.
Rust remains a good option for a future isolated service or data-processing
library, but it is not needed for the initial product surface.
