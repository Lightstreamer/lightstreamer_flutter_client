import 'package:lightstreamer_flutter_client/src/native_bridge.dart';

class AndroidMpnBuilder {
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

  AndroidMpnBuilder();

  AndroidMpnBuilder.from(String notificationFormat) : _notificationFormat = notificationFormat;

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
    return await NativeBridge.instance.invokeMethod('AndroidMpnBuilder.build', arguments);
  }

  AndroidMpnBuilder setCollapseKey(String? collapseKey) {
    _collapseKey = collapseKey;
    return this;
  }

  String? getCollapseKey() {
    return _collapseKey;
  }

  AndroidMpnBuilder setPriority(String? priority) {
    _priority = priority;
    return this;
  }

  String? getPriority() {
    return _priority;
  }

  AndroidMpnBuilder setTimeToLive(String? timeToLive) {
    _timeToLive = timeToLive;
    return this;
  }

  String? getTimeToLiveAsString() {
    return _timeToLive;
  }

  AndroidMpnBuilder setTimeToLiveAsInteger(int? timeToLive) {
    _timeToLive = timeToLive == null ? null : '$timeToLive';
    return this;
  }

  int? getTimeToLiveAsInteger() {
    var t = _timeToLive;
    return t == null ? null : int.parse(t);
  }

  AndroidMpnBuilder setTitle(String? title) {
    _title = title;
    return this;
  }

  String? getTitle() {
    return _title;
  }

  AndroidMpnBuilder setTitleLocKey(String? titleLocKey) {
    _titleLocKey = titleLocKey;
    return this;
  }

  String? getTitleLocKey() {
    return _titleLocKey;
  }

  AndroidMpnBuilder setTitleLocArguments(List<String>? titleLocArguments) {
    _titleLocArguments = titleLocArguments?.toList();
    return this;
  }

  List<String>? getTitleLocArguments() {
    return _titleLocArguments?.toList();
  }

  AndroidMpnBuilder setBody(String? body) {
    _body = body;
    return this;
  }

  String? getBody() {
    return _body;
  }

  AndroidMpnBuilder setBodyLocKey(String? bodyLocKey) {
    _bodyLocKey = bodyLocKey;
    return this;
  }

  String? getBodyLocKey() {
    return _bodyLocKey;
  }

  AndroidMpnBuilder setBodyLocArguments(List<String>? bodyLocArguments) {
    _bodyLocArguments = bodyLocArguments?.toList();
    return this;
  }

  List<String>? getBodyLocArguments() {
    return _bodyLocArguments?.toList();
  }

  AndroidMpnBuilder setIcon(String? icon) {
    _icon = icon;
    return this;
  }

  String? getIcon() {
    return _icon;
  }

  AndroidMpnBuilder setSound(String? sound) {
    _sound = sound;
    return this;
  }

  String? getSound() {
    return _sound;
  }

  AndroidMpnBuilder setTag(String? tag) {
    _tag = tag;
    return this;
  }

  String? getTag() {
    return _tag;
  }

  AndroidMpnBuilder setColor(String? color) {
    _color = color;
    return this;
  }

  String? getColor() {
    return _color;
  }

  AndroidMpnBuilder setClickAction(String? clickAction) {
    _clickAction = clickAction;
    return this;
  }

  String? getClickAction() {
    return _clickAction;
  }

  AndroidMpnBuilder setData(Map<String, String>? data) {
    _data = data == null ? null : Map.from(data);
    return this;
  }

  Map<String, String>? getData() {
    var d = _data;
    return d == null ? null : Map.from(d);
  }
}