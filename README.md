# ShelfNote

Fast, local-first capture for ideas, tasks, things to read, and general notes. It is a small native macOS app: type a thought, put it in a simple bucket, pin the few things that should stay visible, and get back to work.

## What it does

- Captures **Ideas**, **Tasks**, **Read Later**, and **Notes** locally with SwiftData.
- Keeps a pinned shelf for the important few.
- Searches notes and schedules optional local reminders.
- Works without an account or network connection.

## Run and install

Requires macOS 14+ and Xcode Command Line Tools.

```sh
swift test
scripts/build-app.sh
open .build/ShelfNote.app
```

To keep it, drag `.build/ShelfNote.app` into your Applications folder. The first release is intentionally unsigned; macOS may require you to open it from Finder with **Open**. Signed/notarized distribution belongs in a GitHub Release once there is a Developer ID certificate.

## Enable iCloud sync

This package intentionally starts with local storage so it can run without a signed Apple Developer identity. iCloud sync needs a real App ID and CloudKit container owned by your team.

1. Open `Package.swift` in Xcode and give the app target a unique bundle identifier.
2. In **Signing & Capabilities**, add **iCloud** and **CloudKit**; create/select a container such as `iCloud.com.yourteam.ShelfNote`.
3. Replace the placeholder container in `Resources/ShelfNote.entitlements` and attach it to the target.
4. In `ShelfNoteApp.swift`, replace `ModelConfiguration(cloudKitDatabase: .none)` with:

   ```swift
   ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourteam.ShelfNote"))
   ```

5. Run signed builds on devices using the same iCloud account.

iCloud synchronizes the store; it is not a versioned backup. Add Markdown/JSON export before relying on it for irreplaceable notes.

## Repository status

This repository is private while the app is being shaped. No license is included yet; all rights are reserved. Before open-sourcing, add a license, remove any personal iCloud container identifiers, and decide how releases will be signed.
