# RubyClient for iOS

SwiftUI port of RubyClient: a hub of apps plus a private browser, in the ruby theme.

## What's included
- **Ruby Browser** – tabs, private tabs (no history, cookies or site data), searchable history, tracker blocker, share, DuckDuckGo search
- **Web apps** – Discord, Steam
- **Tools** – Weather, Notes, Tasks, Calculator, Converter, Focus Timer, Password Maker

## Not included (not possible or not ported yet)
Ruby VPN / Tor engine tabs (iOS does not allow an app to do this the way the desktop client does), Clip Studio, Game Demos, Accounts, Clipboard history, Secure Vault, QR Studio, add-ons, split view, auto-updater (the App Store handles updates).

## Build
Needs a Mac with Xcode 15+.

```sh
brew install xcodegen
cd ios
xcodegen generate
open RubyClient.xcodeproj
```
Pick your team under Signing & Capabilities, choose a simulator or your iPhone, and press Run.
