# Gym Membership Check-In

A native Android prototype for gym reception staff to register members
and check membership status using a digital QR card.

## Status

The MVP runs on a single Android device and stores member records locally.
Registration, manual ID lookup, and QR scanning from a saved image were
verified in the Android Emulator. Live camera scanning needs a real
device test.

## How it works

1. Select **Register member** and enter the member's name. The app creates
   a one-calendar-month membership starting on the registration date.
2. The app generates a unique member ID and a QR card. Share the QR image
   so the member can save it and show it at reception.
3. Open **Check membership** and scan the QR with the camera, select a
   saved QR image, or enter the member ID manually. The app displays the
   member's name, expiration date, and membership status.

The membership stays active through its expiration date, inclusive.
For example, a membership created on February 2 is active through March 2.

## Project structure

- `app/` — Android app, including registration, QR handling, membership
  lookup, and local storage.
- `gradle/wrapper/` — Gradle Wrapper files.

## Local development

Open the project root in Android Studio and sync Gradle. Select JDK 17 or JDK 21
as the Gradle JDK and use the Gradle Wrapper included in the repository.

```bash
./gradlew assembleDebug
```

To try the MVP on an emulator, run the `app` configuration, register a
test member, and save a screenshot of their QR code. If the screenshot
was saved on your computer, copy it to the emulator's Downloads folder.
Then open **Check membership → Scan QR from image**, select the screenshot,
and check that the member appears with the **Active** status.

## Author

Built by [Yevhen Volboienko](https://www.linkedin.com/in/yevhen-volboienko/) — Senior Android Engineer.
