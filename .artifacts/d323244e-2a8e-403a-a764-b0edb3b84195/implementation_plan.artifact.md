# Implementation Plan - Integrate New Icons Asset

This plan outlines the steps to register the newly added `assets/icons` folder in the project and use a high-resolution icon from it as the primary application logo.

## User Review Required

> [!NOTE]
> **Chosen Asset**
> I will use `assets/icons/android/play_store_512.png` as the new high-resolution logo for the Splash Screen and other UI elements, as it appears to be the high-quality source icon.

> [!IMPORTANT]
> **Launcher Icon Regeneration**
> Do you want me to also run the command to re-generate the Android and iOS home screen launcher icons using this new source?

## Proposed Changes

### 1. Configuration

#### [MODIFY] [pubspec.yaml](file:///home/joviallaps/Desktop/Ub-Hub/pubspec.yaml)
- Add `assets/icons/` and its subdirectories (or just the main ones) to the assets list.
- Update `flutter_launcher_icons` configuration to point to the new 512x512 source icon.

### 2. UI Updates

#### [MODIFY] [SplashScreen](file:///home/joviallaps/Desktop/Ub-Hub/lib/Screens/UI/preview/Navigation/splash_screen.dart)
- Replace `assets/images/logoicon.png` with `assets/icons/android/play_store_512.png`.

#### [MODIFY] [Home](file:///home/joviallaps/Desktop/Ub-Hub/lib/Screens/UI/preview/Navigation/home.dart)
- (Optional) Update any logo usage in the header if applicable.

## Verification Plan

### Automated Steps
- Run `flutter pub get` to ensure assets are registered.

### Manual Verification
1. Restart the app.
2. Verify that the new high-resolution logo appears on the Splash Screen.
3. Check the logs for any "Asset not found" errors.
