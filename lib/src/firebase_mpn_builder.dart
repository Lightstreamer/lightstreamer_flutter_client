/*
 * Copyright (C) 2022 Lightstreamer Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'package:lightstreamer_flutter_client/src/client.dart';

/**
 * Utility class that provides methods to build or parse the JSON structure used to represent the format of a push notification.
 * 
 * It provides getters and setters for the fields of a push notification, 
 * following the format specified by <a href="https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages">FCM REST API</a>.
 * This format is compatible with [MpnSubscription.setNotificationFormat].
 * 
 * - See [MpnSubscription.setNotificationFormat]
 */
class FirebaseMpnBuilder {
  String? _collapseKey;
  String? _priority;
  String? _timeToLive;
  String? _title;
  String? _titleLocKey;
  List<String>? _titleLocArguments;
  String? _body;
  String? _bodyLocKey;
  List<String>? _bodyLocArguments;
  String? _icon;
  String? _sound;
  String? _tag;
  String? _color;
  String? _clickAction;
  Map<String, String>? _data;
  String? _notificationFormat;

  /**
   * Creates an empty object to be used to create a push notification format from scratch.
   * 
   * Use setters methods to set the value of push notification fields.
   */
  FirebaseMpnBuilder();

  /**
   * Creates an object based on the specified push notification format.
   * 
   * Use getter methods to obtain the value of push notification fields.
   * 
   * - [notificationFormat] A JSON structure representing a push notification format.
   * 
   * **Throws** IllegalArgumentException if the notification is not a valid JSON structure.
   */
  FirebaseMpnBuilder.from(String notificationFormat) : _notificationFormat = notificationFormat;

  /**
   * Produces the JSON structure for the push notification format specified by this object.
   * 
   * **Returns** the JSON structure for the push notification format.
   */
  Future<String> build() async {
    var arguments = <String, dynamic>{
      'collapseKey': _collapseKey,
      'priority': _priority,
      'timeToLive': _timeToLive,
      'title': _title,
      'titleLocKey': _titleLocKey,
      'titleLocArguments': _titleLocArguments,
      'body': _body,
      'bodyLocKey': _bodyLocKey,
      'bodyLocArguments': _bodyLocArguments,
      'icon': _icon,
      'sound': _sound,
      'tag': _tag,
      'color': _color,
      'clickAction': _clickAction,
      'data': _data,
      'notificationFormat': _notificationFormat,
    };
    return await NativeBridge.instance.invokeMethod('FirebaseMpnBuilder.build', arguments);
  }

  /**
   * Sets the <code>android.collapse_key</code> field.
   * 
   * - [collapseKey] A string to be used for the <code>android.collapse_key</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setCollapseKey(String? collapseKey) {
    _collapseKey = collapseKey;
    return this;
  }

  /**
   * Gets the value of <code>android.collapse_key</code> field.
   * 
   * **Returns** the value of <code>android.collapse_key</code> field, or null if absent.
   */
  String? getCollapseKey() {
    return _collapseKey;
  }

  /**
   * Sets the <code>android.priority</code> field.
   * 
   * - [priority] A string to be used for the <code>android.priority</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setPriority(String? priority) {
    _priority = priority;
    return this;
  }

  /**
   * Gets the value of <code>android.priority</code> field.
   * 
   * **Returns** the value of <code>android.priority</code> field, or null if absent.
   */
  String? getPriority() {
    return _priority;
  }

  /**
   * Sets the <code>android.ttl</code> field with a string value.
   * 
   * - [timeToLive] A string to be used for the <code>android.ttl</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTimeToLive(String? timeToLive) {
    _timeToLive = timeToLive;
    return this;
  }

  /**
   * Gets the value of <code>android.ttl</code> field as a string.
   * 
   * **Returns** a string with the value of <code>android.ttl</code> field, or null if absent.
   */
  String? getTimeToLiveAsString() {
    return _timeToLive;
  }

  /**
   * Sets the <code>android.ttl</code> field with an integer value.
   * 
   * - [timeToLive] An integer to be used for the <code>android.ttl</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTimeToLiveAsInteger(int? timeToLive) {
    _timeToLive = timeToLive == null ? null : '$timeToLive';
    return this;
  }

  /**
   * Gets the value of <code>android.ttl</code> field as an integer.
   * 
   * **Returns** an integer with the value of <code>android.ttl</code> field, or null if absent.
   */
  int? getTimeToLiveAsInteger() {
    var t = _timeToLive;
    return t == null ? null : int.parse(t);
  }

  /**
   * Sets the <code>android.notification.title</code> field.
   * 
   * - [title] A string to be used for the <code>android.notification.title</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTitle(String? title) {
    _title = title;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.title</code> field.
   * 
   * **Returns** the value of <code>android.notification.title</code> field, or null if absent.
   */
  String? getTitle() {
    return _title;
  }

  /**
   * Sets the <code>android.notification.title_loc_key</code> field.
   * 
   * - [titleLocKey] A string to be used for the <code>android.notification.title_loc_key</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTitleLocKey(String? titleLocKey) {
    _titleLocKey = titleLocKey;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.title_loc_key</code> field.
   * 
   * **Returns** the value of <code>android.notification.title_loc_key</code> field, or null if absent.
   */
  String? getTitleLocKey() {
    return _titleLocKey;
  }

  /**
   * Sets the <code>android.notification.title_loc_args</code> field.
   * 
   * - [titleLocArguments] A list of strings to be used for the <code>android.notification.title_loc_args</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTitleLocArguments(List<String>? titleLocArguments) {
    _titleLocArguments = titleLocArguments?.toList();
    return this;
  }

  /**
   * Gets the value of <code>android.notification.title_loc_args</code> field.
   * 
   * **Returns** a list of strings with the value of <code>android.notification.title_loc_args</code> field, or null if absent.
   */
  List<String>? getTitleLocArguments() {
    return _titleLocArguments?.toList();
  }

  /**
   * Sets the <code>android.notification.body</code> field.
   * 
   * - [body] A string to be used for the <code>android.notification.body</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setBody(String? body) {
    _body = body;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.body</code> field.
   * 
   * **Returns** the value of <code>android.notification.body</code> field, or null if absent.
   */
  String? getBody() {
    return _body;
  }

  /**
   * Sets the <code>android.notification.body_loc_key</code> field.
   * 
   * - [bodyLocKey] A string to be used for the <code>android.notification.body_loc_key</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setBodyLocKey(String? bodyLocKey) {
    _bodyLocKey = bodyLocKey;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.body_loc_key</code> field.
   * 
   * **Returns** the value of <code>android.notification.body_loc_key</code> field, or null if absent.
   */
  String? getBodyLocKey() {
    return _bodyLocKey;
  }

  /**
   * Sets the <code>android.notification.body_loc_args</code> field.
   * 
   * - [bodyLocArguments] A list of strings to be used for the <code>android.notification.body_loc_args</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setBodyLocArguments(List<String>? bodyLocArguments) {
    _bodyLocArguments = bodyLocArguments?.toList();
    return this;
  }

  /**
   * Gets the value of <code>android.notification.body_loc_args</code> field.
   * 
   * **Returns** a list of strings with the value of <code>android.notification.body_loc_args</code> field, or null if absent.
   */
  List<String>? getBodyLocArguments() {
    return _bodyLocArguments?.toList();
  }

  /**
   * Sets the <code>android.notification.icon</code> field.
   * 
   * - [icon] A string to be used for the <code>android.notification.icon</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setIcon(String? icon) {
    _icon = icon;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.icon</code> field.
   * 
   * **Returns** the value of <code>android.notification.icon</code> field, or null if absent.
   */
  String? getIcon() {
    return _icon;
  }

  /**
   * Sets the <code>android.notification.sound</code> field.
   * 
   * - [sound] A string to be used for the <code>android.notification.sound</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setSound(String? sound) {
    _sound = sound;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.sound</code> field.
   * 
   * **Returns** the value of <code>android.notification.sound</code> field, or null if absent.
   */
  String? getSound() {
    return _sound;
  }

  /**
   * Sets the <code>android.notification.tag</code> field.
   * 
   * - [tag] A string to be used for the <code>android.notification.tag</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setTag(String? tag) {
    _tag = tag;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.tag</code> field.
   * 
   * **Returns** the value of <code>android.notification.tag</code> field, or null if absent.
   */
  String? getTag() {
    return _tag;
  }

  /**
   * Sets the <code>android.notification.color</code> field.
   * 
   * - [color] A string to be used for the <code>android.notification.color</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setColor(String? color) {
    _color = color;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.color</code> field.
   * 
   * **Returns** the value of <code>android.notification.color</code> field, or null if absent.
   */
  String? getColor() {
    return _color;
  }

  /**
   * Sets the <code>android.notification.click_action</code> field.
   * 
   * - [clickAction] A string to be used for the <code>android.notification.click_action</code> field value, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setClickAction(String? clickAction) {
    _clickAction = clickAction;
    return this;
  }

  /**
   * Gets the value of <code>android.notification.click_action</code> field.
   * 
   * **Returns** the value of <code>android.notification.click_action</code> field, or null if absent.
   */
  String? getClickAction() {
    return _clickAction;
  }

  /**
   * Sets sub-fields of the <code>android.data</code> field.
   * 
   * - [data] A map to be used for sub-fields of the <code>android.data</code> field, or null to clear it.
   * 
   * **Returns** this MpnBuilder object, for fluent use.
   */
  FirebaseMpnBuilder setData(Map<String, String>? data) {
    _data = data == null ? null : Map.from(data);
    return this;
  }

  /**
   * Gets sub-fields of the <code>android.data</code> field.
   * 
   * **Returns** A map with sub-fields of the <code>android.data</code> field, or null if absent. 
   */
  Map<String, String>? getData() {
    var d = _data;
    return d == null ? null : Map.from(d);
  }
}