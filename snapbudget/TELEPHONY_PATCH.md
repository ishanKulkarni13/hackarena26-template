# Telephony Package Patch Guide

The `telephony` package (v0.2.0) is **abandoned/unmaintained** and its Android build file is missing a `namespace` field required by modern Android Gradle Plugin (AGP 7.3+). Without this patch, the project **will not build** and you'll see:

```
A problem occurred configuring project ':telephony'.
> Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
   > Namespace not specified. Specify a namespace in the module's build file: ...telephony-0.2.0\android\build.gradle
```

This patch must be applied **once per machine** (or after every `flutter clean` + `flutter pub get` on a fresh clone).

---

## Who needs to do this?

Everyone who clones this repo and tries to `flutter run` or build the app on **their own machine**.

---

## Step-by-Step Fix

### Step 1 — Make sure you've run `flutter pub get` first

Before patching, you need the telephony package to be downloaded into your pub cache. Run this in the project folder:

```
flutter pub get
```

If you haven't installed Flutter yet, stop here and install it from https://docs.flutter.dev/get-started/install first.

---

### Step 2 — Find the file you need to edit

The file is buried inside Flutter's package cache on your machine. The path depends on your OS:

**Windows:**
```
C:\Users\<YOUR_USERNAME>\AppData\Local\Pub\Cache\hosted\pub.dev\telephony-0.2.0\android\build.gradle
```
Replace `<YOUR_USERNAME>` with your actual Windows username (the name you log in with).

Example: if your username is `john`, the path is:
```
C:\Users\john\AppData\Local\Pub\Cache\hosted\pub.dev\telephony-0.2.0\android\build.gradle
```

**macOS / Linux:**
```
~/.pub-cache/hosted/pub.dev/telephony-0.2.0/android/build.gradle
```

> **Tip:** The `AppData` folder is hidden on Windows. To navigate there, press `Win + R`, type `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\telephony-0.2.0\android` and press Enter. This opens it directly in File Explorer.

---

### Step 3 — Open the file in a text editor

Right-click `build.gradle` → **Open with** → **Notepad** (or any text editor like VS Code, Notepad++).

The file currently looks like this:

```groovy
apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    compileSdkVersion 31
    ...
}
```

---

### Step 4 — Add the `namespace` line

Find this exact block inside the file:

```groovy
android {
    compileSdkVersion 31
```

Change it to:

```groovy
android {
    namespace 'com.shounakmulay.telephony'
    compileSdkVersion 31
```

You are adding **exactly one line**: `namespace 'com.shounakmulay.telephony'` right after `android {`.

Save the file.

---

### Step 5 — Verify the fix (optional but recommended)

Open the file again and confirm it now contains the namespace line. It should look like:

```groovy
android {
    namespace 'com.shounakmulay.telephony'
    compileSdkVersion 31

    kotlinOptions {
        jvmTarget = "1.8"
    }
    ...
}
```

---

### Step 6 — Build the app

Go back to the project folder in your terminal/command prompt and run:

```
flutter run
```

The build should now succeed. If you still see errors unrelated to telephony, they are separate issues.

---

## Applying the patch automatically (PowerShell — Windows only)

If you want to skip the manual editing, paste this into PowerShell from the project folder:

```powershell
$path = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\telephony-0.2.0\android\build.gradle"
(Get-Content $path) -replace "android \{", "android {`n    namespace 'com.shounakmulay.telephony'" | Set-Content $path
Write-Host "Patch applied successfully."
```

---

## Applying the patch automatically (bash — macOS/Linux only)

```bash
FILE="$HOME/.pub-cache/hosted/pub.dev/telephony-0.2.0/android/build.gradle"
sed -i "s/android {/android {\n    namespace 'com.shounakmulay.telephony'/" "$FILE"
echo "Patch applied successfully."
```

---

## Why does this happen?

Flutter stores downloaded packages in a global "pub cache" on your machine. When a package is outdated and doesn't include a field required by newer Android build tools, **every machine that builds the project** needs to patch its own local copy. There is no way to ship this fix inside the repo itself because the file lives outside the project folder.

---

## Does this need to be done again?

Yes, in these situations:

| Situation | Need to re-patch? |
|---|---|
| First time cloning the repo | Yes |
| New team member on their machine | Yes |
| After `flutter pub cache clean` + `flutter pub get` | Yes |
| After switching Flutter SDK versions (if pub cache changes) | Yes |
| Already patched and just pulling new commits | No |

---

## I asked AI to help — what do I tell it?

Paste this into your AI chat:

> I need to patch the telephony 0.2.0 Flutter package. The file at `C:\Users\<MY_USERNAME>\AppData\Local\Pub\Cache\hosted\pub.dev\telephony-0.2.0\android\build.gradle` is missing `namespace 'com.shounakmulay.telephony'` inside the `android { }` block. Please add it right after the `android {` line and save the file.
