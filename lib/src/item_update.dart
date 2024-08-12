import 'package:flutter/services.dart';

interface class ItemUpdate {
  final String? _itemName;
  final int _itemPos;
  final bool _isSnapshot;
  final Map<String, String> _changedFields;
  final Map<String, String> _fields;
  final Map<String, String> _jsonFields;
  final Map<int, String> _changedFieldsByPosition;
  final Map<int, String> _fieldsByPosition;
  final Map<int, String> _jsonFieldsByPosition;

  // TODO make private
  ItemUpdate(MethodCall call) :
    _itemName = call.arguments['itemName'],
    _itemPos = call.arguments['itemPos'],
    _isSnapshot = call.arguments['isSnapshot'],
    _changedFields = (call.arguments['changedFields'] as Map<Object?, Object?>).cast(),
    _fields = (call.arguments['fields'].cast() as Map<Object?, Object?>).cast(),
    _jsonFields = (call.arguments['jsonFields'] as Map<Object?, Object?>).cast(),
    _changedFieldsByPosition = (call.arguments['changedFieldsByPosition'] as Map<Object?, Object?>).cast(),
    _fieldsByPosition = (call.arguments['fieldsByPosition'] as Map<Object?, Object?>).cast(),
    _jsonFieldsByPosition = (call.arguments['jsonFieldsByPosition'] as Map<Object?, Object?>).cast();

  String? getItemName() {
    return _itemName;
  }

  int getItemPos() {
    return _itemPos;
  }

  bool isSnapshot() {
    return _isSnapshot;
  }

  String? getValue(String fieldName) {
    return _fields[fieldName];
  }

  String? getValueByPosition(int fieldPosition) {
    return _fieldsByPosition[fieldPosition];
  }

  bool isValueChanged(String fieldName) {
    return _changedFields.containsKey(fieldName);
  }

  bool isValueChangedByPosition(int fieldPosition) {
    return _changedFieldsByPosition.containsKey(fieldPosition);
  }

  String? getValueAsJSONPatchIfAvailable(String fieldName) {
    return _jsonFields[fieldName];
  }

  String? getValueAsJSONPatchIfAvailableByPosition(int fieldPosition) {
    return _jsonFieldsByPosition[fieldPosition];
  }

  Map<String,String> getChangedFields() {
    return {..._changedFields};
  }

  Map<int,String> getChangedFieldsByPosition() {
    return {..._changedFieldsByPosition};
  }

  Map<String,String> getFields() {
    return {..._fields};
  }

  Map<int,String> getFieldsByPosition() {
    return {..._fieldsByPosition};
  }
}