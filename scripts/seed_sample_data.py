#!/usr/bin/env python3

"""Add representative diary data without replacing existing user entries."""

from __future__ import annotations

import argparse
import sqlite3
from datetime import date, timedelta
from pathlib import Path


def sample_entries(today: date) -> list[tuple[date, float | None, str]]:
    entries: list[tuple[date, float | None, str]] = []

    recent = [
        (-1, 8.5, "# A quiet start\n\nI made breakfast and had time to read."),
        (-3, 6.75, "## A busy day\n\nToo many meetings, but an evening walk helped."),
        (-6, 9.0, "# A good day\n\nI finished an important task and cooked something new."),
        (-9, None, "A day I want to remember even though I did not rate it."),
        (-13, 7.25, "The week had a nice balance of work, rest, and time outside."),
    ]
    for offset, rating, text in recent:
        entries.append((today + timedelta(days=offset), rating, text))

    monthly = [
        (1, 7.5, "A productive month with a few slow weekends."),
        (2, 5.25, "A difficult month, but I learned what boundaries I need."),
        (3, 8.75, "A month full of small moments with friends."),
        (6, 6.5, "A month of steady progress."),
    ]
    for months_ago, rating, text in monthly:
        month = today.month - months_ago
        year = today.year
        while month <= 0:
            month += 12
            year -= 1
        day = min(today.day, 28)
        entries.append((date(year, month, day), rating, text))

    older = [
        (-365, 7.0, "One year ago: a fresh beginning."),
        (-730, 8.25, "Two years ago: a memorable adventure."),
    ]
    for offset, rating, text in older:
        entries.append((today + timedelta(days=offset), rating, text))
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database",
        type=Path,
        default=Path.home() / ".local/share/udaet/udaet.sqlite",
        help="Path to the Udaet SQLite database",
    )
    args = parser.parse_args()

    if not args.database.exists():
        parser.error(f"database does not exist: {args.database}")

    connection = sqlite3.connect(args.database)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        inserted = 0
        skipped = 0
        for day, rating, markdown in sample_entries(date.today()):
            day_text = day.isoformat()
            exists = connection.execute(
                "SELECT 1 FROM days WHERE day = ?", (day_text,)
            ).fetchone()
            if exists:
                skipped += 1
                continue
            connection.execute(
                "INSERT INTO days(day, rating) VALUES (?, ?)", (day_text, rating)
            )
            connection.execute(
                "INSERT INTO entries(day, markdown) VALUES (?, ?)",
                (day_text, markdown),
            )
            inserted += 1
        connection.commit()
    finally:
        connection.close()

    print(f"Inserted {inserted} sample entries; skipped {skipped} existing days.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
