# Privacy policy

Last updated: 2026-11-27

Llavero is a family vault for passwords and codes. This policy explains, in plain language, what happens to your information.

## Who is responsible

Made by Dayern Gomez (Neryad). You can write to neryadg@gmail.com.

## What data we collect

None. Llavero does not collect personal data:

- There are no accounts or user registrations.
- There are no servers and no analytics.
- There are no ads, crash reports or trackers.
- The app has no INTERNET permission and works fully offline.

## Where your data lives

Your entries stay on your device in a file encrypted with AES-256-GCM. The key is protected by your PIN and, if you enable it, by the device biometrics (Android Keystore or iOS Keychain).

The app never sees or stores your fingerprint or face: the operating system handles it.

Cloud and device backups of the vault file are disabled.

## When data leaves your device

Only when you choose to export or share it:

- An encrypted `.llavero` backup, protected by a password you choose.
- An unencrypted PDF, JSON or CSV file, if you ask for it.
- The Wi-Fi QR code, which contains that network's password.

In unencrypted PDF, JSON and CSV files, secret values are replaced with `[oculto]` by default. They are only included if you turn on "Include secrets in plain text" and re-authenticate.

After that, you and the apps you choose are responsible for those files and for anything you share.

## Clipboard

When you copy a secret, the app tries to clear the clipboard after the time you configured. This is best effort: other apps may read the clipboard in the meantime.

## Permissions used

Only biometrics, and only if you turn it on. The app does not ask for contacts, photos, location or internet.

## No recovery

If you lose your PIN, it cannot be recovered. Your encrypted backup is the only way back to your data.

## Children

Llavero is not directed at children. It is meant for family use.

## Changes

If this policy changes, the changes are announced in new app versions.

## Contact

neryadg@gmail.com

© 2026 Dayern Gomez (Neryad)
