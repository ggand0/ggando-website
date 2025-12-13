+++
title = "How to sell your Rust app on macOS app store"
date = 2025-05-08
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/rust_appstore_16x9_moz.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust", "mac", "winit"]
+++

<img src="https://ggando.b-cdn.net/rust_appstore_moz.jpg" alt="img0" width="500" style="display: block; margin: auto;"/>

### Introduction
Last week I released my Rust app ([an image viewer](https://github.com/ggand0/viewskater)) on macOS app store. The whole submission process is tedious, and I had to repeat the upload steps multiple times to fix issues with my binaries. I’m writing this post to document the entire process step by step.

Initially, I referred to [this gist](https://gist.github.com/rsms/929c9c2fec231f0cf843a1a746a416f5), but it’s aimed at distributing apps outside the App Store. If you're targeting the App Store, some of the steps are different, which I’ll cover here.


### Step 0: Patch winit to Remove Private API Usage
Before starting the App Store release process, you need to patch winit if your app depends on it.
As of May 2025, winit (0.30.x) still includes a reference to a private macOS API: `_CGSSetWindowBackgroundBlurRadius`.
Even if your app doesn't use any blur functionality, the App Store will reject your binary just for containing the symbol.
To fix this, you need to replace the deprecated call with a safe alternative using `NSVisualEffectView`. Refer to [this github issue](https://github.com/rust-windowing/winit/issues/4205) for details.

#### How to Patch
1. Fork winit or make a local copy.
2. Replace the `set_blur` function in `winit/src/platform_impl/apple/appkit/window_delegate.rs`
	with the following version (based on @Areopagitics' fix):
    <details>
    <summary>Click to see the code</summary>

    ```rust
    pub fn set_blur(&self, blur: bool) {
        let window = self.window();

        if blur {
            let effect_view: &objc2::runtime::AnyObject = unsafe {
                let alloc: &objc2::runtime::AnyObject = msg_send![class!(NSVisualEffectView), alloc];
                msg_send![alloc, init]
            };

            unsafe {
                let _: () = msg_send![effect_view, setMaterial: objc2::sel!(NSVisualEffectMaterialAppearanceBased)];
                let _: () = msg_send![effect_view, setState: objc2::sel!(NSVisualEffectStateActive)];
                let _: () = msg_send![effect_view, setBlendingMode: objc2::sel!(NSVisualEffectBlendingModeBehindWindow)];
                let _: () = msg_send![effect_view, setTranslatesAutoresizingMaskIntoConstraints: false];
            }

            let content_view: &objc2::runtime::AnyObject = unsafe { msg_send![window, contentView] };

            unsafe {
                let _: () = msg_send![content_view, addSubview: effect_view];
            }

            unsafe {
                let leading_anchor: &objc2::runtime::AnyObject = msg_send![effect_view, leadingAnchor];
                let trailing_anchor: &objc2::runtime::AnyObject = msg_send![effect_view, trailingAnchor];
                let top_anchor: &objc2::runtime::AnyObject = msg_send![effect_view, topAnchor];
                let bottom_anchor: &objc2::runtime::AnyObject = msg_send![effect_view, bottomAnchor];

                let content_leading: &objc2::runtime::AnyObject = msg_send![content_view, leadingAnchor];
                let content_trailing: &objc2::runtime::AnyObject = msg_send![content_view, trailingAnchor];
                let content_top: &objc2::runtime::AnyObject = msg_send![content_view, topAnchor];
                let content_bottom: &objc2::runtime::AnyObject = msg_send![content_view, bottomAnchor];

                let _: () = msg_send![leading_anchor, constraintEqualToAnchor: content_leading];
                let _: () = msg_send![trailing_anchor, constraintEqualToAnchor: content_trailing];
                let _: () = msg_send![top_anchor, constraintEqualToAnchor: content_top];
                let _: () = msg_send![bottom_anchor, constraintEqualToAnchor: content_bottom];
            }
        } else {
            let content_view: &objc2::runtime::AnyObject = unsafe { msg_send![window, contentView] };
            let subviews: &objc2::runtime::AnyObject = unsafe { msg_send![content_view, subviews] };
            let count: usize = unsafe { msg_send![subviews, count] };
            for i in 0..count {
                let subview: &objc2::runtime::AnyObject = unsafe { msg_send![subviews, objectAtIndex: i] };
                let is_visual_effect_view: bool = unsafe { msg_send![subview, isKindOfClass: class!(NSVisualEffectView)] };
                if is_visual_effect_view {
                    unsafe { let _: () = msg_send![subview, removeFromSuperview]; }
                }
            }
        }
    }
    ```
    </details>
3. Point your Cargo.toml to your patched winit:
```toml
winit = { git = "https://github.com/yourname/winit", branch = "your-patched-branch" }
```

### Step 1: Enroll in Apple Developer Program
Unfortunately, a paid Apple Developer Program membership ($99/year) is required to distribute apps on the App Store. Hopefully, this post will help you understand how the submission process would look like and whether it's worth the effort.

You need to agree to the Apple Developer Program License Agreement which basically says you're liable to all the issues caused by your app while you keep the ownership.

This account will be used to create certificates, code-sign app binaries, and define your app on App Store Connect in later steps.

Relevant links:
- [Apple Developer account page](https:/developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)


#### 1-1. Create Bundle ID for your app
1. Go to Apple Developer account page -> **"Identifiers"**
2. Click the "+" icon
3. Select "App IDs" -> Continue
4. Select "App"
5. Fill out the "Bundle ID": e.g. "com.ggando.viewskater"
6. Fill out "Description": e.g. "A fast image viewer"
7. Enable any of Capabilities required by your app -> "Register"

#### 1-2. Create your app
1. Go to App Store Connect / Apps
2. Click the "+" icon -> "New App"
3. Fill out the New App form:  
Platforms: "macOS"  
Name: your app name  
Primary Language: your language  
Bundle ID: your app identifier created in **1-1**  
SKU: some ID you'd like to use, it can be anything. e.g. "viewskater"  
User Access: "Full Access"

After this you'll see a page like this for configuring screenshots, description, app pricing, etc.

<img src="https://ggando.b-cdn.net/app_store_connect0.png" alt="img0" width="500" style="display: block; margin: auto;"/>

### Step 2: Bundle your app
I use the [cargo-bundle](https://github.com/burtonageo/cargo-bundle) crate to build a **.app bundle** for macOS. After specifying app metadata in your `Cargo.toml`, you can run `cargo bundle --release`.
```toml
# Used on macOS for generating .app bundles via `cargo bundle`
[target.'cfg(target_os = "macos")'.dev-dependencies]
cargo-bundle = "0.6.0"

[package.metadata.bundle]
name = "ViewSkater"
identifier = "com.ggando.viewskater"
icon = ["assets/ViewSkater.icns"]
short_description = "A fast image viewer for browsing large collections of images."
```

#### Prepare app icon
App Store Connect requires you to include a **.icns** file with specific resolutions. If it’s missing, you’ll get an email like this:

> ITMS-90236: Missing required icon - The application bundle does not contain an icon in ICNS format, containing both a 512x512 and a 512x512@2x image.

@2x means "Retina" versions (2× resolution). So in this case, 512×512px and 1024x1024px PNGs are missing.
It looks like you could include @2x images with cargo-bundle if you explicitly name the icon files like "128x128@2x.png", but I had better luck with using a manually generated .icns. Here's how:

1. Create an icon.iconset folder with files named exactly:
```
icon_16x16.png
icon_16x16@2x.png
icon_32x32.png
icon_32x32@2x.png
icon_128x128.png
icon_128x128@2x.png
icon_256x256.png
icon_256x256@2x.png
icon_512x512.png
icon_512x512@2x.png
```
where the resolution of `icon_16x16.png` is 16x16px, `icon_16x16@2x.png` is 32x32px, and so on.


2. Use macOS built-in tool:
```
iconutil -c icns -o ViewSkater.icns icon.iconset
```
3. Put the resulting .icns in your project, then specify in Cargo.toml
```
[package.metadata.bundle]
name = "ViewSkater"
identifier = "com.ggando.viewskater"
icon = ["assets/ViewSkater.icns"]
short_description = "A fast image viewer for browsing large collections of images."
```
4. cargo bundle —release  will include the .icns icon


### Step 3: Set Up Info.plist, Entitlements, and Provisioning Profile
Before signing and packaging your Rust app, you need to prepare a few required files inside the .app bundle:
#### 1. Info.plist
You need an Info.plist file at `YourApp.app/Contents/Info.plist`.
This tells macOS basic metadata about your app.
At minimum, your Info.plist should include:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.yourcompany.yourapp</string>
  <key>CFBundleName</key>
  <string>YourApp</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string> <!-- or whatever minimum macOS you want to support -->
</dict>
</plist>
```

Notes:
- CFBundleIdentifier must match the Bundle ID you created on App Store Connect earlier.
- LSMinimumSystemVersion is required. Without it, your build will be rejected:

> ITMS-90983: Missing LSMinimumSystemVersion - The LSMinimumSystemVersion key must be present in the Info.plist file when submitting a macOS app.


#### 2. Entitlements.plist
Entitlements define permissions your app needs.
Basic Entitlements.plist for a simple Rust app (no special permissions) looks like this:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key>
  <true/>
</dict>
</plist>
```

Notes:
- App Sandbox is required for App Store apps.
- If your app needs more capabilities (like network access, file access, etc.), you need to add more keys.

Missing this file will trigger a rejection after upload:

> TMS-90296: App sandbox not enabled - The following executables must include the 'com.apple.security.app-sandbox' entitlement with a Boolean value of true in the entitlements property list: [[com.ggando.viewskater.pkg/Payload/ViewSkater.app/Contents/MacOS/viewskater]] 

#### 3. Provisioning Profile
You need a `.provisionprofile` (also called a provisioning profile) tied to your App ID.
Steps:
1. Go to Apple Developer account page -> "Certificates" -> in the "Certificates, Identifiers & Profiles" page, select the **"Profiles"** tab -> click the "+" icon
2. Select the "App Store Connect" option under the "Distribution" section -> "Continue" -> Select an App ID from the pulldown menu -> "Continue" -> generate a provision profile
3. Download the .provisionprofile file.
4. Copy it into your .app bundle at:
	`YourApp.app/Contents/embedded.provisionprofile`

I'm not 100% sure, but I believe this file is required. In my case, including only the Entitlements.plist resulted in a rejection with the following error, suggesting the provisioning profile must also be present:

> ITMS-90287: Invalid Code Signing Entitlements - The entitlements in your app bundle signature do not match the ones that are contained in the provisioning profile. The bundle contains a key that is not included in the provisioning profile: 'com.apple.application-identifier' in '\<path\>/ViewSkater.app/Contents/MacOS/viewskater'.

#### 4. Remove the quarantine attribute
Finally, run this to clean up any macOS quarantine flag
```bash
xattr -cr <your app>.app`.
```
If you skip this step, App Store Connect may reject the upload:

> ITMS-91109: Invalid package contents - The package contains one or more files with the com.apple.quarantine extended file attribute, such as :“\<path\>/ViewSkater.app/Contents/Resources/ViewSkater.icns”. This attribute isn’t permitted in macOS apps distributed on TestFlight or the App Store. Please remove the attribute from all files within your app and upload again.

### Step 4. Code-sign the .app
Code signing proves that your app comes from a verified Apple developer and is required for App Store submission.

Before you can sign your app, you’ll need to generate a certificate request and download the necessary certificates from the Apple Developer site.

#### 4-1. Create and install a Distribution Certificate
You’ll need a **“3rd Party Mac Developer Application”** certificate to code-sign your .app.

1. Open Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority....
2. Fill in your info, select “Saved to disk”, and generate a `.certSigningRequest` (**CSR**) file.
3. Go to the Apple Developer Certificates page.
4. Click +, and under Production, choose **“Mac App Distribution”** (this is officially called 3rd Party Mac Developer Application).
5. Upload your CSR (certificate signing request) file.
6. Download the generated .cer file and double-click it to install into Keychain Access.

Confirm the installation by running `security find-identity -v` in your terminal.
You should see an entry like this:
```
$ security find-identity -v
1) <ID> "3rd Party Mac Developer Application: Your Name (Team ID)"
1 valid identities found
```
Copy this exact string: "3rd Party Mac Developer Application: Your Name (Team ID)". You’ll use it in the codesign command in the next step.

#### 4-2. Run code-signing command
Before submitting your app, you must code-sign the .app itself using your 3rd Party Mac Developer Application certificate.
```bash
codesign --deep --force --options runtime \
  --sign "3rd Party Mac Developer Application: Your Name (Team ID)" \
  /path/to/YourApp.app
```

Explanation:
- --deep ensures that all nested contents (binaries, libraries) are also signed.
- --force replaces any existing signatures if needed.
- --options runtime enables hardened runtime, which is required for App Store submission.
- --sign specifies the application signing certificate.
Important:
- The .appmust be signed correctly before you package it into a .pkg.
- If you package an unsigned .app, Apple will reject your submission.

### Step 5. Create a .pkg Installer for App Store Submission
#### 5-1. Get certificates for installers
First, you need a **“3rd Party Mac Developer Installer”** certificate (this is different from the one we used for code-signing).
The process the same as the previous "3rd Party Mac Developer Application" certificate we used for code-signing. You can re-use the same CSR file you generated before.
1. Go to Apple Developer Certificates.
2. Click +, and under Production, choose **“Mac Installer Distribution”** (this is officially called 3rd Party Mac Developer Installer).
3. Upload your CSR (certificate signing request) just like before.
4. Download and install the .cer file into Keychain Access.
This certificate will be used to sign the installer package (.pkg), not the app itself.
Confirm the installation by running `security find-identity -v` again. You should see two entries including "3rd Party Mac Developer Installer".

Initially I used a wrong certificate for this ("Developer ID Installer") and got rejected after the upload:
> ITMS-90237: The product archive package's signature is invalid. Ensure that it is signed with your '3rd Party Mac Developer Installer' certificate.

#### 5-2. Run packagebuild command
Once you have the app (.app) already signed and ready, you can create the .pkg using productbuild:

```bash
productbuild \
  --component /path/to/YourApp.app /Applications \
  --sign "3rd Party Mac Developer Installer: Your Name (Team ID)" \
  /path/to/output/YourApp.pkg
```
Explanation:
- --component tells where your .app is and where it should be installed (usually /Applications).
- --sign uses the installer certificate to sign the package.
- The last part is the output .pkg file.
This .pkg is what you upload to App Store Connect when submitting your app for review.

### Step 6. Upload the .pkg with Transporter
Transporter is Apple’s official tool for uploading app builds to App Store Connect. It's a way to deliver signed binaries to the App Store.

#### 6-1. Wrap the `.pkg` in an `.itmsp` directory
Transporter doesn’t accept raw `.pkg` files. You need to wrap your package in an .itmsp directory, which contains both the .pkg and a metadata.xml descriptor.

1. Create a directory, e.g. ViewSkater.itmsp
2. Copy the .pkg file into it
3. Create a metadata.xml file like this:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://apple.com/itunes/importer" version="software5.10">
    <software_assets apple_id="<your app id>" app_platform="osx">
        <asset type="product-archive">
            <data_file>
                <file_name>ViewSkater.pkg</file_name>
                <size><file size></size>
                <checksum type="md5"><md5></checksum>
            </data_file>
        </asset>
    </software_assets>
</package>
```

As for the file size and checksum values, use these commands:
```bash
stat -f%z ViewSkater.pkg
md5 ViewSkater.pkg
```

Reflect the actual values in `metadata.xml` and place it under the .itmsp directory:
```
ViewSkater.itmsp
|--ViewSkater.pkg
|--metadata.xml
```

#### 6-2. Create an app-specific password
Another annoying step but you need to set up an [app-specific password](https://support.apple.com/en-us/102654) in macOS Keychain. Go to https://appleid.apple.com/account/manage and setup an app-specific password.

1. Go to https://appleid.apple.com.
2. Sign into your apple account from the "Sign in" menu at the top right corner
3. In the Sign-In and Security section, select **App-Specific Passwords**.
4. Select Generate an app-specific password or select the Add button , then follow the steps on your screen.
5. Enter or paste the app-specific password into the password field of the app.

[Reference](https://discussions.apple.com/thread/254805086?sortBy=rank)

#### 6-3. Run the transporter tool to upload your app
We can now upload the prepared app package to App Store Connect. Install the [Transporter app](https://apps.apple.com/us/app/transporter/id1450874784?mt=12). In my case the GUI app didn't work and only gave me vague errors so I used the command line tool:
```bash
/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
  -m upload \
  -f /Users/gota/ggando/viewskater/target/release/bundle/osx/ViewSkater.itmsp \
  -u <my_email> \
  -p <app_specific_password>
```

If successful, you’ll see a confirmation in the terminal, and App Store Connect will also send you an email within a few minutes.

### Step 7. Fix any issues from App Store Connect
If there are problems with your upload (missing icons, metadata, signatures, etc.), you’ll get an email titled something like: "Action needed: The uploaded build for <app name> has one or more issues". You’ll need to fix all the critical ones before your app can move to review.

#### Example email
```text
Hello,

We noticed one or more issues with a recent delivery for the following app:

 • VIewSkater
 • App Apple <ID>
 • Version 0.2.3
 • Build 20250424.45313
Please correct the following issues and upload a new binary to App Store Connect.

ITMS-90242: The product archive is invalid - The Info.plist must contain a LSApplicationCategoryType key, whose value is the UTI for a valid category. For more details, see 'Submitting your Mac apps to the App Store'.

ITMS-90869: Invalid bundle - The “ViewSkater.app” bundle supports arm64 but not Intel-based Mac computers. Your build must include the x86_64 architecture to support Intel-based Mac computers. To support arm64 only, your macOS deployment target must be 12.0 or higher. For details, view: https://developer.apple.com/documentation/xcode/building_a_universal_macos_binary. 

ITMS-90296: App sandbox not enabled - The following executables must include the 'com.apple.security.app-sandbox' entitlement with a Boolean value of true in the entitlements property list: [[com.ggando.viewskater.pkg/Payload/ViewSkater.app/Contents/MacOS/viewskater]] Refer to App Sandbox page at https://developer.apple.com/documentation/security/app_sandbox for more information on sandboxing your app. 

ITMS-90237: The product archive package's signature is invalid. Ensure that it is signed with your '3rd Party Mac Developer Installer' certificate. 

ITMS-90983: Missing LSMinimumSystemVersion - The LSMinimumSystemVersion key must be present in the Info.plist file when submitting a macOS app. For details, visit: https://developer.apple.com/documentation/bundleresources/information_property_list/lsminimumsystemversion. 

ITMS-90236: Missing required icon - The application bundle does not contain an icon in ICNS format, containing both a 512x512 and a 512x512@2x image. For further assistance, see the Human Interface Guidelines at https://developer.apple.com/design/human-interface-guidelines/foundations/app-icons/. 

Though you are not required to fix the following issues, we wanted to make you aware of them:

ITMS-90889: 'Cannot be used with TestFlight because the bundle at “ViewSkater.app” is missing a provisioning profile. Main bundles are expected to have provisioning profiles in order to be eligible for TestFlight.'

Apple Developer Relations
```

If your .app bundle includes a valid provisioning profile, you can also test it via TestFlight. This is useful because Apple enforces a stricter sandbox in TestFlight than on your own machine. For instance, my app includes a CPU memory monitor, but it didn’t work in TestFlight because it couldn’t access process-level system info.


### Step 8. Prepare your app info
Prepare preview video, screenshots, description and configure pricing.
A few things to keep in mind:
- The preview video requirements: 1920x1080px or 1080x1920px, 15~30 seconds duration, 30 FPS
- Screenshots resolution: Either of 1280x800px, 1440x900px, 2560x1600px, or 2880x1800px ([reference](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/))
- Most assets(preview video, screenshots, description, etc.) **can’t be edited** after release unless you submit a new build
- You **can** update promotional text, copyright info, and pricing after release

### Step 9. Submit your app for App Review
If everything looks good, go ahead and hit the **"Add for Review"** button at the top right corner of your app page on App Store Connect. If something goes wrong like an obvious crash, you'll get an email like: "We noticed an issue with your submission". Just fix the issue and re-upload a new binary.

### Step 10. Confirm the release
Once your app is approved, it should appear on the App Store within 24 hours. Cheers!

For reference, [here's the link to my app](https://apps.apple.com/us/app/viewskater/id6745068907) if you want to check it out.

---

### Bonus: Automating the Tedious Parts

After repeating this process a few times, I generated a shell script with GPT to automate the bundling, signing, packaging, and uploading steps.

[Here’s the script as a GitHub Gist](https://gist.github.com/ggand0/0f6c266a999cf9b03f9ca560352c2bb0). Edit the constants at the top before running.
  