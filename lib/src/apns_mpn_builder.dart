import 'package:lightstreamer_flutter_client/src/client.dart';

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

  ApnsMpnBuilder();

  ApnsMpnBuilder.from(String notificationFormat) : _notificationFormat = notificationFormat;

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

  ApnsMpnBuilder setAlert(String? val) {
    _alert = val;
    return this;
  }

  String? getAlert() {
    return _alert;
  }

  ApnsMpnBuilder setBadge(String? val) {
    _badge = val;
    return this;
  }

  String? getBadge() {
    return _badge;
  }

  ApnsMpnBuilder setBody(String? val) {
    _body = val;
    return this;
  }

  String? getBody() {
    return _body;
  }

  ApnsMpnBuilder setBodyLocArguments(List<String>? val) {
    _bodyLocArguments = val?.toList();
    return this;
  }

  List<String>? getBodyLocArguments() {
    return _bodyLocArguments?.toList();
  }

  ApnsMpnBuilder setBodyLocKey(String? val) {
    _bodyLocKey = val;
    return this;
  }

  String? getBodyLocKey() {
    return _bodyLocKey;
  }

  ApnsMpnBuilder setCategory(String? val) {
    _category = val;
    return this;
  }

  String? getCategory() {
    return _category;
  }

  ApnsMpnBuilder setContentAvailable(String? val) {
    _contentAvailable = val;
    return this;
  }

  String? getContentAvailable() {
    return _contentAvailable;
  }

  ApnsMpnBuilder setMutableContent(String? val) {
    _mutableContent = val;
    return this;
  }

  String? getMutableContent() {
    return _mutableContent;
  }

  ApnsMpnBuilder setCustomData(Map<String, dynamic>? val) {
    _customData = val == null ? null : Map.from(val);
    return this;
  }

  Map<String, dynamic>? getCustomData() {
    var d = _customData;
    return d == null ? null : Map.from(d);
  }

  ApnsMpnBuilder setLaunchImage(String? val) {
    _launchImage = val;
    return this;
  }

  String? getLaunchImage() {
    return _launchImage;
  }

  ApnsMpnBuilder setLocActionKey(String? val) {
    _locActionKey = val;
    return this;
  }

  String? getLocActionKey() {
    return _locActionKey;
  }

  ApnsMpnBuilder setSound(String? val) {
    _sound = val;
    return this;
  }

  String? getSound() {
    return _sound;
  }

  ApnsMpnBuilder setThreadId(String? val) {
    _threadId = val;
    return this;
  }

  String? getThreadId() {
    return _threadId;
  }

  ApnsMpnBuilder setTitle(String? val) {
    _title = val;
    return this;
  }

  String? getTitle() {
    return _title;
  }

  ApnsMpnBuilder setSubtitle(String? val) {
    _subtitle = val;
    return this;
  }

  String? getSubtitle() {
    return _subtitle;
  }

  ApnsMpnBuilder setTitleLocArguments(List<String>? val) {
    _titleLocArguments = val?.toList();
    return this;
  }

  List<String>? getTitleLocArguments() {
    return _titleLocArguments?.toList();
  }

  ApnsMpnBuilder setTitleLocKey(String? val) {
    _titleLocKey = val;
    return this;
  }

  String? getTitleLocKey() {
    return _titleLocKey;
  }
}