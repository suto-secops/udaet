# Udaet

Udaet is a local-first diary for KDE Plasma, focused on daily writing,
eudaimonia ratings, image galleries, and long-term trends.

Udaet is distributed under the [PolyForm Noncommercial License 1.0.0](LICENSE).

## Current status

The repository contains the first functional Qt 6/Kirigami vertical slice:
local SQLite persistence, day navigation, Markdown source editing, rendered
preview, and optional ratings. Product work continues around:

- one Markdown diary entry per local calendar day;
- an optional eudaimonia rating from `0.00` to `10.00`;
- copied PNG, JPEG, and WebP attachments in a per-day gallery;
- calendar visibility for ratings;
- week, month, year, and all-time trend views;
- self-contained HTML export for preset or custom date ranges.

See [docs/architecture.md](docs/architecture.md) for the design boundaries
and decisions.

## Building

Udaet uses CMake, Qt 6, and KDE Kirigami 6:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/udaet
```

The exact package names depend on the Arch/KDE packaging state. Runtime data
will be stored under the standard Qt application data location; imported
images are copied there rather than referenced in place.
