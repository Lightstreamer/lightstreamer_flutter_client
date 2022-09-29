## 1.0.3

### Bug Fixes:

    - Fixed a bug in the Android implementation of the sendmessage functions that prevented it from properly returning a success result.

## 1.0.2

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
