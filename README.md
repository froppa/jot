# Jot

Fast, local-first capture for ideas, tasks, things to read, and general notes. It is a small native macOS app: type a thought, put it in a simple bucket, pin the few things that should stay visible, and get back to work.

## What it does

- Captures **Ideas**, **Tasks**, **Read Later**, and **Notes** locally with SwiftData.
- Keeps a pinned shelf for the important few.
- Searches notes and schedules optional local reminders.
- Works without an account or network connection.

## Run and install

Requires macOS 14+, Xcode, and [mise](https://mise.jdx.dev/). Install mise with `brew install mise`, then verify the Xcode toolchain and run the app:

```sh
make setup
make test
make install
```

`make install` builds Jot, installs it in `/Applications`, and opens it. `make help` lists the available commands. The underlying mise tasks are also available directly, for example `mise run build`. Jot intentionally uses Xcode’s Swift toolchain because SwiftData is an Apple framework, not mise’s standalone Swift runtime. Project tasks do not auto-install unrelated tools from your global mise configuration.

The first release is intentionally unsigned; macOS may require you to open it from Finder with **Open**. Signed/notarized distribution belongs in a GitHub Release once there is a Developer ID certificate.

## Enable iCloud sync

This package intentionally starts with local storage so it can run without a signed Apple Developer identity. iCloud sync needs a real App ID and CloudKit container owned by your team.

1. Open `Package.swift` in Xcode and give the app target a unique bundle identifier.
2. In **Signing & Capabilities**, add **iCloud** and **CloudKit**; create/select a container such as `iCloud.com.yourteam.Jot`.
3. Replace the placeholder container in `Resources/Jot.entitlements` and attach it to the target.
4. In `JotApp.swift`, replace `ModelConfiguration(cloudKitDatabase: .none)` with:

   ```swift
   ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourteam.Jot"))
   ```

5. Run signed builds on devices using the same iCloud account.

iCloud synchronizes the store; it is not a versioned backup. Add Markdown/JSON export before relying on it for irreplaceable notes.

## Repository status

This repository is private while the app is being shaped. No license is included yet; all rights are reserved. Before open-sourcing, add a license, remove any personal iCloud container identifiers, and decide how releases will be signed.
