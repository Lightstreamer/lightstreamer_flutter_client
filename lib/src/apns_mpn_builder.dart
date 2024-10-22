import 'package:lightstreamer_flutter_client/src/client.dart';

/**
 Utility class that provides methods to build or parse the JSON structure used to represent the format of a push notification.
 
 It provides properties and methods to get and set the fields of a push notification, following the format specified by Apple's Push Notification service (APNs).
 This format is compatible with [MpnSubscription.setNotificationFormat].
 
 - See [MpnSubscription.setNotificationFormat]
 */
class ApnsMpnBuilder {
  String? _alert;
  String? _badge;
  String? _body;
  List<String>? _bodyLocArguments;
  String? _bodyLocKey;
  String? _category;
  String? _contentAvailable;
  String? _mutableContent;
  Map<String, dynamic>? _customData;
  String? _launchImage;
  String? _locActionKey;
  String? _sound;
  String? _threadId;
  String? _title;
  String? _subtitle;
  List<String>? _titleLocArguments;
  String? _titleLocKey;
  String? _notificationFormat;

  /**
   Creates an empty object to be used to create a push notification format from scratch.
  
   Use setters methods to set the value of push notification fields.
   */
  ApnsMpnBuilder();

  /**
   Creates an object based on the specified push notification format.
   
   Use properties and setter methods to get and set the value of push notification fields.
   
   - [notificationFormat]: A JSON structure representing a push notification format. The notification must be a valid JSON structure.
   */
  ApnsMpnBuilder.from(String notificationFormat) : _notificationFormat = notificationFormat;

  /**
   Produces the JSON structure for the push notification format specified by this object.
   */
  Future<String> build() async {
    var arguments = <String, dynamic>{
      'alert': _alert,
      'badge': _badge,
      'body': _body,
      'bodyLocArguments': _bodyLocArguments,
      'bodyLocKey': _bodyLocKey,
      'category': _category,
      'contentAvailable': _contentAvailable,
      'mutableContent': _mutableContent,
      'customData': _customData,
      'launchImage': _launchImage,
      'locActionKey': _locActionKey,
      'sound': _sound,
      'threadId': _threadId,
      'title': _title,
      'subtitle': _subtitle,
      'titleLocArguments': _titleLocArguments,
      'titleLocKey': _titleLocKey,
      'notificationFormat': _notificationFormat,
    };
    return await NativeBridge.instance.invokeMethod('ApnsMpnBuilder.build', arguments);
  }

  /**
   Sets the `aps.alert` field.
   
   - [alert]: A string to be used for the `aps.alert` field value, or nil to clear it.
   */
  ApnsMpnBuilder setAlert(String? val) {
    _alert = val;
    return this;
  }

  /**
   Value of the `aps.alert` field.
   */
  String? getAlert() {
    return _alert;
  }

  /**
   Sets the `aps.badge` field with a string value.
   
   - [badge]: A string to be used for the `aps.badge` field value, or nil to clear it.
   */
  ApnsMpnBuilder setBadge(String? val) {
    _badge = val;
    return this;
  }

  /**
   Value of the `aps.badge` field as a string value.
   */
  String? getBadge() {
    return _badge;
  }

  /**
   Sets the `aps.alert.body` field.
   
   - [body]: A string to be used for the `aps.alert.body` field value, or nil to clear it.
   */
  ApnsMpnBuilder setBody(String? val) {
    _body = val;
    return this;
  }

  /**
   Value of the `aps.alert.body` field.
   */
  String? getBody() {
    return _body;
  }

  /**
   Sets the `aps.alert.loc-args` field.
   
   - [bodyLocArguments]: An array of strings to be used for the `aps.alert.loc-args` field value, or nil to clear it.
   */
  ApnsMpnBuilder setBodyLocArguments(List<String>? val) {
    _bodyLocArguments = val?.toList();
    return this;
  }

  /**
   Value of the `aps.alert.loc-args` field as an array of strings.
   */
  List<String>? getBodyLocArguments() {
    return _bodyLocArguments?.toList();
  }

  /**
   Sets the `aps.alert.loc-key` field.
   
   - [bodyLocKey]: A string to be used for the `aps.alert.loc-key` field value, or nil to clear it.
   */
  ApnsMpnBuilder setBodyLocKey(String? val) {
    _bodyLocKey = val;
    return this;
  }

  /**
   Value of the `aps.alert.loc-key` field.
   */
  String? getBodyLocKey() {
    return _bodyLocKey;
  }

  /**
   Sets the `aps.category` field.
   
   - [category]: A string to be used for the `aps.category` field value, or nil to clear it.
   */
  ApnsMpnBuilder setCategory(String? val) {
    _category = val;
    return this;
  }

  /**
   Value of the `aps.category` field.
   */
  String? getCategory() {
    return _category;
  }

  /**
   Sets the `aps.content-available` field with a string value.
   
   - [contentAvailable]: A string to be used for the `aps.content-available` field value, or nil to clear it.
   */
  ApnsMpnBuilder setContentAvailable(String? val) {
    _contentAvailable = val;
    return this;
  }

  /**
   Value of the `aps.content-available` field as a string value.
   */
  String? getContentAvailable() {
    return _contentAvailable;
  }

  /**
   Sets the `aps.mutable-content` field with a string value.
   
   - [mutableContent]: A string to be used for the `aps.mutable-content` field value, or nil to clear it.
   */
  ApnsMpnBuilder setMutableContent(String? val) {
    _mutableContent = val;
    return this;
  }

  /**
   Value of the `aps.mutable-content` field as a string value.
   */
  String? getMutableContent() {
    return _mutableContent;
  }

  /**
   Sets fields in the root of the notification format (excluding `aps`).
   
   - [customData]: A dictionary to be used for fields in the root of the notification format (excluding `aps`), or nil to clear them.
   */
  ApnsMpnBuilder setCustomData(Map<String, dynamic>? val) {
    _customData = val == null ? null : Map.from(val);
    return this;
  }

  /**
   Fields in the root of the notification format (excluding `aps`).
   */
  Map<String, dynamic>? getCustomData() {
    var d = _customData;
    return d == null ? null : Map.from(d);
  }

  /**
   Sets the `aps.alert.launch-image` field.
   
   - [launchImage]: A string to be used for the `aps.alert.launch-image` field value, or nil to clear it.
   */
  ApnsMpnBuilder setLaunchImage(String? val) {
    _launchImage = val;
    return this;
  }

  /**
   Value of the `aps.alert.launch-image` field.
   */
  String? getLaunchImage() {
    return _launchImage;
  }

  /**
   Sets the `aps.alert.action-loc-key` field.
   
   - [locActionKey]: A string to be used for the `aps.alert.action-loc-key` field value, or nil to clear it.
   */
  ApnsMpnBuilder setLocActionKey(String? val) {
    _locActionKey = val;
    return this;
  }

  /**
   Value of the `aps.alert.action-loc-key` field.
   */
  String? getLocActionKey() {
    return _locActionKey;
  }

  /**
   Sets the `aps.sound` field.
   
   - [sound]: A string to be used for the `aps.sound` field value, or nil to clear it.
   */
  ApnsMpnBuilder setSound(String? val) {
    _sound = val;
    return this;
  }

  /**
   Value of the `aps.sound` field.
   */
  String? getSound() {
    return _sound;
  }

  /**
   Sets the `aps.thread-id` field.
   
   - [threadId]: A string to be used for the `aps.thread-id` field value, or nil to clear it.
   */
  ApnsMpnBuilder setThreadId(String? val) {
    _threadId = val;
    return this;
  }

  /**
   Value of the `aps.thread-id` field.
   */
  String? getThreadId() {
    return _threadId;
  }

  /**
   Sets the `aps.alert.title` field.
   
   - [title]: A string to be used for the `aps.alert.title` field value, or nil to clear it.
   */
  ApnsMpnBuilder setTitle(String? val) {
    _title = val;
    return this;
  }

  /**
   Value of the `aps.alert.title` field.
   */
  String? getTitle() {
    return _title;
  }

  /**
   Sets the `aps.alert.subtitle` field.
   
   - [subtitle]: A string to be used for the `aps.alert.subtitle` field value, or nil to clear it.
   */
  ApnsMpnBuilder setSubtitle(String? val) {
    _subtitle = val;
    return this;
  }

  /**
   Value of the `aps.alert.subtitle` field.
   */
  String? getSubtitle() {
    return _subtitle;
  }

  /**
   Sets the `aps.alert.title-loc-args` field.
   
   - [titleLocArguments]: An array of strings to be used for the `aps.alert.title-loc-args` field value, or nil to clear it.
   */
  ApnsMpnBuilder setTitleLocArguments(List<String>? val) {
    _titleLocArguments = val?.toList();
    return this;
  }

  /**
   Value of the `aps.alert.title-loc-args` field.
   */
  List<String>? getTitleLocArguments() {
    return _titleLocArguments?.toList();
  }

  /**
   Sets the `aps.alert.title-loc-key` field.
   
   - [titleLocKey]: A string to be used for the `aps.alert.title-loc-key` field value, or nil to clear it.
   */
  ApnsMpnBuilder setTitleLocKey(String? val) {
    _titleLocKey = val;
    return this;
  }

  /**
   Value of the `aps.alert.title-loc-key` field.
   */
  String? getTitleLocKey() {
    return _titleLocKey;
  }
}