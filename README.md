# Jot

A small native macOS app for capturing notes without an account or network
connection. Write something down, sort it into a category, and pin the notes
you want to keep visible.

## What it does

- Stores notes locally with SwiftData.
- Groups them into Inbox, Notes, Ideas, Tasks, and Read Later.
- Supports editing, search within a category, and a pinned shelf.
- Displays inline Markdown formatting while keeping the original text.

## Build and run

Requires macOS 14+, Xcode, and [mise](https://mise.jdx.dev/).
Jot uses Xcode's Swift toolchain for SwiftUI and SwiftData.

```sh
make setup
make test
make run
```

`make run` builds `.build/Jot.app` and opens it. To install the app in
`/Applications` instead, run `make install`. `make help` lists the commands.

The build script creates an app bundle without a signing or notarization step.
There is no signed release download yet.

## Current limits

Storage is local only. iCloud sync, export, and a UI for scheduling reminders
are not implemented. The reminder model and scheduler are groundwork rather
than a usable feature.

There is no in-app backup or restore. Keep that in mind before using Jot as the
only copy of important notes.

## Code

`Sources/Jot/JotApp.swift` contains the interface, `Note.swift` defines the data
model and category queries, and `Tests/JotTests` covers query ordering, note
identity, and Markdown rendering. `scripts/build-app.sh` assembles the app bundle.

Licensed under the [MIT License](LICENSE).
