# Android Production Release Signing Guide

This guide explains how to generate, configure, and automate cryptographic `.jks` keystore signing for Orbitune's Android release builds, both in **GitHub Actions CI/CD** and **locally**.

---

## 1. Overview

Android requires all application packages (`.apk` and `.aab`) distributed in release mode to be digitally signed with a cryptographic certificate.
Orbitune's build configuration in `android/app/build.gradle.kts` dynamically checks for the presence of signing credentials:
- **With signing credentials configured (`android/key.properties`)**: Produces officially signed production release APKs (`app+<arch>+release.apk`).
- **Without credentials**: Safely falls back to debug certificate signing for local testing and developer builds.

---

## 2. Generating a Production Keystore (.jks)

If you do not already have an upload or release keystore, generate one using Java's `keytool` utility.

### Command for Windows (PowerShell / Command Prompt):
```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Command for Linux / macOS:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Prompt Details:
- **Keystore password**: Enter a secure password (e.g. `MyKeystorePass123!`).
- **First and last name / Org**: Enter your developer or organization name.
- **Key password**: Press `Enter` to use the same password as the keystore password, or choose a custom key password.

> [!CAUTION]
> **Backup your Keystore and Passwords Safely!**
> If you lose your `.jks` file or passwords, you will **not** be able to publish app updates to existing users or the Google Play Store. Keep an encrypted backup in a secure location (e.g., 1Password, Bitwarden, or an offline drive).

---

## 3. Configuring Release Signing in GitHub Actions CI/CD

To keep your keystore and passwords secure, never commit binary `.jks` files into the Git repository. Instead, we encode the keystore into Base64 and store it in **GitHub Repository Secrets**.

### Step A: Encode the Keystore to Base64

Run the appropriate command in the folder containing `upload-keystore.jks`:

#### On Windows (PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```
*(The base64 string is now in your clipboard)*

#### On Linux:
```bash
base64 -w 0 upload-keystore.jks | xclip -selection clipboard
```

#### On macOS:
```bash
base64 -i upload-keystore.jks | pbcopy
```

---

### Step B: Add Secrets to GitHub

1. Open your repository on GitHub: `https://github.com/<owner>/<repo>`.
2. Navigate to **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions**.
3. Click the **New repository secret** button and add these 4 secrets:

| Secret Name | Example / Value | Notes |
| :--- | :--- | :--- |
| `KEYSTORE_BASE64` | `MIIDVzCCAj+gAwIBAgIE...` | Paste the Base64 string from Step A |
| `KEYSTORE_PASSWORD` | `YourKeystorePassword` | The keystore password you created |
| `KEY_ALIAS` | `upload` | The key alias specified in `keytool` |
| `KEY_PASSWORD` | `YourKeyPassword` | The key password |

---

## 4. How the GitHub Actions Workflow Handles Signing

During CI runs (`.github/workflows/build.yml`), the workflow automatically:
1. Detects if `KEYSTORE_BASE64` secret is set.
2. Decodes the Base64 string into `android/app/upload-keystore.jks`.
3. Creates `android/key.properties` with the credentials.
4. Executes `flutter build apk --release --split-per-abi`.
5. Renames and packages the outputs as:
   - `app+arm64-v8a+release.apk`
   - `app+armeabi-v7a+release.apk`
   - `app+x86_64+release.apk`
6. Uploads the signed APKs as downloadable workflow artifacts.

---

## 5. Local Release Signing Setup (Optional)

If you want to compile signed release builds directly on your local workstation:

1. Copy your `upload-keystore.jks` file into `android/app/upload-keystore.jks`.
2. Create a file named `key.properties` inside the `android/` folder:
   ```properties
   storePassword=YourKeystorePassword
   keyPassword=YourKeyPassword
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Run the split APK build:
   ```bash
   flutter build apk --release --split-per-abi
   ```
4. Output APKs will be located in `build/app/outputs/flutter-apk/`.

> [!NOTE]
> `.gitignore` is already pre-configured to ignore `*.jks`, `*.keystore`, and `key.properties`. Never use `git add -f` on these files.

---

## 6. Verifying Signed APKs

You can verify that an APK was signed correctly using the Android SDK `apksigner` tool:

```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
Output should show `Verifies: true` along with your certificate details.
