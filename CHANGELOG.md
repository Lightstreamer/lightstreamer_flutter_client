# Lightstreamer Flutter Plugin Changelog

## Unreleased
*Requires Lightstreamer Server 8.0.0 or later.*

**Breaking:** Removed item-group, field-schema and COMMAND second-level
field-schema accessors. Use explicit item and field lists instead, including
for MPN subscriptions. Lists and names must be non-empty when configured;
names may contain spaces, numeric-only strings, Unicode and control characters.
Inactive list setters accept null; both lists are required before subscribing.

**Breaking:** `onItemLostUpdates` now requires `bool isOverflow`. Server
overflow reports true; Data Adapter loss reports false, with -1 for an unknown
count. The second-level overflow callback is unchanged.

**Added:** Adapter health callbacks, item stale/resume callbacks and Web MPN
copy constructors. MPN property events retain the names `group` and `schema`,
but getters now expose the corresponding explicit lists.


## 2.4.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.3.0*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.3.3*<br/>
*Based on Lightstreamer Swift Client SDK 6.5.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 5 Nov 2026*

**Changed:** Migrated the Web implementation to modern Dart JavaScript interoperability, preserving its public API. Removed the direct `js` dependency and raised the minimum Dart SDK to 3.3.0.


## 2.3.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.3.3*<br/>
*Based on Lightstreamer Swift Client SDK 6.5.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 3 Nov 2026*

**New:** Added Swift Package Manager integration for iOS and macOS, while retaining CocoaPods support.


## 2.2.1
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.3.0*<br/>
*Based on Lightstreamer Swift Client SDK 6.3.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 11 Mar 2026*

**Fixed:** Fixed a duplicate resource conflict in the Android build (`META-INF/versions/9/OSGI-INF/MANIFEST.MF`) caused by transitive OkHttp dependencies.


## 2.2.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.3.0*<br/>
*Based on Lightstreamer Swift Client SDK 6.3.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 11 Mar 2026*

Replaced the `MethodChannel` with an `EventChannel` to deliver events from the native Lightstreamer Client SDKs to the Flutter plugin, as `EventChannel` handles real-time events more efficiently.


## 2.1.4
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.2*<br/>
*Based on Lightstreamer Swift Client SDK 6.3.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 24 Jul 2025*

### New Features

Added the experimental method `LightstreamerClient.reset` for mobile and desktop platforms, which resets the state of the underlying native Lightstreamer Client library. When using hot restart in an IDE like Visual Studio Code, the Flutter app is restarted without resetting native platform state. Calling `reset()` at app startup ensures the native Lightstreamer Client is refreshed, maintaining consistent behavior across development cycles.


## 2.1.3
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 13*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.2*<br/>
*Based on Lightstreamer Swift Client SDK 6.3.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 21 Jul 2025*

Updated the iOS and macOS library dependencies to version 6.3.0 of the Swift Client SDK.


## 2.1.2
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 12*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.2*<br/>
*Based on Lightstreamer Swift Client SDK 6.2.1*<br/>
*Based on Lightstreamer Web Client SDK 9.2.3*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0*<br/>
*Made available on 26 Feb 2025*

Updated library dependencies to the latest versions.


## 2.1.1
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 12*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.2.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.2*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0-beta.1*<br/>
*Made available on 4 Feb 2025*

**Fixed:** `ItemUpdate.getChangedFields` and other `ItemUpdate` methods that threw a `ClassCastException` when the returned map contained null values. This bug affected the Android, iOS and macOS targets.

**Fixed:** `ItemUpdate` methods, such as `getValue` and similar, that returned an empty string when a field was null. This bug affected the Windows target.


## 2.1.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 12*<br/>
*Compatible with macOS 11 (Big Sur)*<br/>
*Compatible with Windows 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 3.7.0*<br/>
*May not be compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.2.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.1*<br/>
*Based on Lightstreamer C++ Client SDK 1.0.0-beta.1*<br/>
*Made available on 11 Dec 2024*

### New Features

Added support for macOS and Windows platforms. For installation and quickstart, refer to the [README](https://github.com/Lightstreamer/lightstreamer_flutter_client/blob/2.1.0/README.md).

### Breaking Changes

Increased the minimum version of Flutter. The plugin now requires Flutter 3.7.0 or above. 


## 2.0.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 12*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*NOT Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.2.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.2.0*<br/>
*Based on Lightstreamer Web Client SDK 9.2.1*<br/>
*Made available on 5 Nov 2024*

Aligned the plugin API with the other Lightstreamer Client SDKs.\
The older API, available in version 1.3.2 and earlier, has been removed.\
For a quick start with the new API, refer to the [README](https://github.com/Lightstreamer/lightstreamer_flutter_client/blob/2.0.0/README.md).


## 1.4.0-dev.3
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.1.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.1.1*<br/>
*Based on Lightstreamer Web Client SDK 9.1.1*<br/>
*Made available on 12 Jun 2024*

Experimental version providing an alternative API that supports multiple active sessions.

**NB** This version is deprecated and users are encouraged to upgrade to version 2.0.0, which offers significantly more functionality.


## 1.3.2
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.1.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.1.1*<br/>
*Based on Lightstreamer Web Client SDK 9.1.1*<br/>
*Made available on 4 Jul 2024*

Fixed a bug where subscription listeners were not returning update values correctly if the server-sent fields contained the `|` character. This resulted in listeners returning only a portion of the field values.


## 1.3.1
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.1.1*<br/>
*Based on Lightstreamer Swift Client SDK 6.1.1*<br/>
*Based on Lightstreamer Web Client SDK 9.1.1*<br/>
*Made available on 31 Jan 2024*

Updated the following dependencies: 

- Lightstreamer Android Client to version 5.1.1
- Lightstreamer Swift Client to version 6.1.1


## 1.3.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.1.0*<br/>
*Based on Lightstreamer Swift Client SDK 6.1.0*<br/>
*Based on Lightstreamer Web Client SDK 9.1.0*<br/>
*Made available on 19 Dec 2023*

Updated the following dependencies: Lightstreamer Android Client to version 5.1.


## 1.2.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 3.1.3*<br/>
*Compatible with Flutter 1.20*<br/>
*May not be compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.0.0*<br/>
*Based on Lightstreamer Swift Client SDK 6.1.0*<br/>
*Based on Lightstreamer Web Client SDK 9.0.0*<br/>
*Made available on 4 Dec 2023*

Added support for Flutter Web based on Lightstreamer Web Client SDK 9.0.0.

Raised the minimum Dart compatibility to version 3.1.3.


## 1.1.1
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Compatible with Android 8 (API 26)*<br/>
*Compatible with iOS 10*<br/>
*Compatible with Dart 2.12*<br/>
*Compatible with Flutter 1.20*<br/>
*Compatible with code developed for the previous version*<br/>
*Based on Lightstreamer Android Client SDK 5.0.0*<br/>
*Based on Lightstreamer Swift Client SDK 6.0.1*<br/>
*Made available on 24 Aug 2023*

Fixed a bug that could cause a client error on iOS when the subscribed items or fields had names containing the character `+`.


## 1.1.0
*Compatible with Lightstreamer Server since 7.4.0*<br/>
*Not compatible with code developed for the previous version.*<br/>
*Made available on 18 Jul 2023*

Method `LightstreamerFlutterClient.subscribe`: converted the second, third and fourth positional parameters in named parameters having the names *itemList*, *fieldList* and *parameters*.
  Added the named parameters *itemGroup* and *fieldSchema*.

Updated the following dependencies: Lightstreamer Swift Client to version 6.0 and Lightstreamer Android Client to version 5.0.


## 1.0.4
*Compatible with Lightstreamer Server since 7.3.2*<br/>
*Compatible with code developed with the previous version.*<br/>

Updated the Lightstreamer Swift Client dependency.

## 1.0.3
*Compatible with Lightstreamer Server since 7.2.0*<br/>
*Compatible with code developed with the previous version.*<br/>

### Bug Fixes:

    - Fixed a bug in the Android implementation of the sendmessage functions that prevented it from properly returning a success result.

## 1.0.2
*Compatible with Lightstreamer Server since 7.2.0*<br/>
*Compatible with code developed with the previous version.*<br/>

### Implemented enhancements:

    - Added support for iOS.

## 1.0.1

### Implemented enhancements:

    - Fix Second level Command mode subscription.
    - Conforming to pub.dev recommendations for some details

## 1.0.0

The first version of our Flutter plugin, wrapping our Android client library.
iOS will be added next.

### Supported functionality

    - Create a Lightstreamer Client Session by passing ConnectionOptions and ConnectionDetails while invoking connect method; contentLength, serverInstanceAddressIgnored and slowingEnabled are not supported yet
    - Close the Lightstreamer Client Session by invoking disconnect method
    - Get current status of a Lightstreamer Client Session by invoking getStatus method
    - Listen for Realtime connection state changes using the 'com.lightstreamer.lightstreamer_flutter_client.status' message channel
    - Subscribe and unsubscribe for Realtime updates  by invoking subcribe and unsubscribe method
    - Listen for Realtime updates using a 'com.lightstreamer.lightstreamer_flutter_client.realtime' message channel
    - Publishing messages on the Lightstreamer Client Session by invoking sendMessage or sendMessageExt methods
    - Listen for sendmessage feedbacks using a  'com.lightstreamer.lightstreamer_flutter_client.messages' message channel
    - MPN module not supported yet
