part of 'client.dart';

/**
 * Contains all the information related to an update of the field values for an item.
 *  
 * It reports all the new values of the fields. <BR>
 * 
 * <b>COMMAND Subscription</b><BR>
 * If the involved Subscription is a COMMAND Subscription, then the values for the current 
 * update are meant as relative to the same key. <BR>
 * Moreover, if the involved Subscription has a two-level behavior enabled, then each update 
 * may be associated with either a first-level or a second-level item. In this case, the reported 
 * fields are always the union of the first-level and second-level fields and each single update 
 * can only change either the first-level or the second-level fields (but for the "command" field, 
 * which is first-level and is always set to "UPDATE" upon a second-level update); note 
 * that the second-level field values are always null until the first second-level update 
 * occurs). When the two-level behavior is enabled, in all methods where a field name has to 
 * be supplied, the following convention should be followed:<BR>
 * <ul>
 *  <li>The field name can always be used, both for the first-level and the second-level fields. 
 *  In case of name conflict, the first-level field is meant.</li>
 *  <li>The field position can always be used; however, the field positions for the second-level 
 *  fields start at the highest position of the first-level field list + 1. If a field schema had 
 *  been specified for either first-level or second-level Subscriptions, then client-side knowledge 
 *  of the first-level schema length would be required.</li>
 *</ul>
 */
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

  ItemUpdate._(MethodCall call) :
    _itemName = call.arguments['itemName'],
    _itemPos = call.arguments['itemPos'],
    _isSnapshot = call.arguments['isSnapshot'],
    _changedFields = (call.arguments['changedFields'] as Map<Object?, Object?>).cast(),
    _fields = (call.arguments['fields'].cast() as Map<Object?, Object?>).cast(),
    _jsonFields = (call.arguments['jsonFields'] as Map<Object?, Object?>).cast(),
    _changedFieldsByPosition = (call.arguments['changedFieldsByPosition'] as Map<Object?, Object?>).cast(),
    _fieldsByPosition = (call.arguments['fieldsByPosition'] as Map<Object?, Object?>).cast(),
    _jsonFieldsByPosition = (call.arguments['jsonFieldsByPosition'] as Map<Object?, Object?>).cast();

  /**
   * Inquiry method that retrieves the name of the item to which this update pertains.
   *  
   * The name will be null if the related Subscription was initialized using an "Item Group".
   * 
   * **Returns** The name of the item to which this update pertains.
   * - See [Subscription.setItemGroup]
   * - See [Subscription.setItems]
   */
  String? getItemName() {
    return _itemName;
  }

  /**
   * Inquiry method that retrieves the position in the "Item List" or "Item Group" of the item to which this update pertains.
   * 
   * **Returns** The 1-based position of the item to which this update pertains.
   * - See [Subscription.setItemGroup]
   * - See [Subscription.setItems]
   */
  int getItemPos() {
    return _itemPos;
  }

  /**
   * Inquiry method that asks whether the current update belongs to the item snapshot (which carries the current item state at the time of Subscription). 
   * 
   * Snapshot events are sent only if snapshot 
   * information was requested for the items through [Subscription.setRequestedSnapshot]
   * and precede the real time events. Snapshot information take different forms in different 
   * subscription modes and can be spanned across zero, one or several update events. In particular:
   * <ul>
   *  <li>if the item is subscribed to with the RAW subscription mode, then no snapshot is 
   *  sent by the Server;</li>
   *  <li>if the item is subscribed to with the MERGE subscription mode, then the snapshot consists 
   *  of exactly one event, carrying the current value for all fields;</li>
   *  <li>if the item is subscribed to with the DISTINCT subscription mode, then the snapshot 
   *  consists of some of the most recent updates; these updates are as many as specified 
   *  through [Subscription#setRequestedSnapshot], unless fewer are available;</li>
   *  <li>if the item is subscribed to with the COMMAND subscription mode, then the snapshot 
   *  consists of an "ADD" event for each key that is currently present.</li>
   * </ul>
   * Note that, in case of two-level behavior, snapshot-related updates for both the first-level item
   * (which is in COMMAND mode) and any second-level items (which are in MERGE mode) are qualified with 
   * this flag.
   * 
   * **Returns** true if the current update event belongs to the item snapshot; false otherwise.
   */
  bool isSnapshot() {
    return _isSnapshot;
  }

  /**
   * Returns the current value for the specified field.
   * 
   * - [fieldName] The field name as specified within the "Field List".
   * 
   * **Throws** IllegalArgumentException if the specified field is not part of the Subscription.
   * 
   * **Returns** The value of the specified field; it can be null in the following cases:<BR>
   * <ul>
   *  <li>a null value has been received from the Server, as null is a possible value for a field;</li>
   *  <li>no value has been received for the field yet;</li>
   *  <li>the item is subscribed to with the COMMAND mode and a DELETE command is received 
   *  (only the fields used to carry key and command information are valued).</li>
   * </ul>
   * - See [Subscription.setFields]
   */
  String? getValue(String fieldName) {
    return _fields[fieldName];
  }

  /**
   * Returns the current value for the specified field.
   * 
   * - [fieldPosition] The 1-based position of the field within the "Field List" or "Field Schema".
   * 
   * **Throws** IllegalArgumentException if the specified field is not part of the Subscription.
   * 
   * **Returns** The value of the specified field; it can be null in the following cases:<BR>
   * <ul>
   *  <li>a null value has been received from the Server, as null is a possible value for a field;</li>
   *  <li>no value has been received for the field yet;</li>
   *  <li>the item is subscribed to with the COMMAND mode and a DELETE command is received 
   *  (only the fields used to carry key and command information are valued).</li>
   * </ul>
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  String? getValueByPosition(int fieldPosition) {
    return _fieldsByPosition[fieldPosition];
  }

  /**
   * Inquiry method that asks whether the value for a field has changed after the reception of the last update from the Server for an item. 
   * 
   * If the Subscription mode is COMMAND then the change is meant as 
   * relative to the same key.
   * - [fieldName] The field name as specified within the "Field List".
   * 
   * **Throws** IllegalArgumentException if the specified field is not part of the Subscription.
   * 
   * **Returns** Unless the Subscription mode is COMMAND, the return value is true in the following cases:
   * <ul>
   *  <li>It is the first update for the item;</li>
   *  <li>the new field value is different than the previous field 
   *  value received for the item.</li>
   * </ul>
   *  If the Subscription mode is COMMAND, the return value is true in the following cases:
   * <ul>
   *  <li>it is the first update for the involved key value (i.e. the event carries an "ADD" command);</li>
   *  <li>the new field value is different than the previous field value received for the item, 
   *  relative to the same key value (the event must carry an "UPDATE" command);</li>
   *  <li>the event carries a "DELETE" command (this applies to all fields other than the field 
   *  used to carry key information).</li>
   * </ul>
   * In all other cases, the return value is false.
   * - See [Subscription.setFields]
   */
  bool isValueChanged(String fieldName) {
    return _changedFields.containsKey(fieldName);
  }

  /**
   * Inquiry method that asks whether the value for a field has changed after the reception of the last update from the Server for an item. 
   * 
   * If the Subscription mode is COMMAND then the change is meant as 
   * relative to the same key.
   * - [fieldPosition] The 1-based position of the field within the "Field List" or "Field Schema".
   * 
   * **Throws** IllegalArgumentException if the specified field is not part of the Subscription.
   * 
   * **Returns** Unless the Subscription mode is COMMAND, the return value is true in the following cases:
   * <ul>
   *  <li>It is the first update for the item;</li>
   *  <li>the new field value is different than the previous field 
   *  value received for the item.</li>
   * </ul>
   *  If the Subscription mode is COMMAND, the return value is true in the following cases:
   * <ul>
   *  <li>it is the first update for the involved key value (i.e. the event carries an "ADD" command);</li>
   *  <li>the new field value is different than the previous field value received for the item, 
   *  relative to the same key value (the event must carry an "UPDATE" command);</li>
   *  <li>the event carries a "DELETE" command (this applies to all fields other than the field 
   *  used to carry key information).</li>
   * </ul>
   * In all other cases, the return value is false.
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  bool isValueChangedByPosition(int fieldPosition) {
    return _changedFieldsByPosition.containsKey(fieldPosition);
  }

  /**
   * Inquiry method that gets the difference between the new value and the previous one
   * as a JSON Patch structure, provided that the Server has used the JSON Patch format
   * to send this difference, as part of the "delta delivery" mechanism.
   * 
   * This, in turn, requires that:<ul>
   * <li>the Data Adapter has explicitly indicated JSON Patch as the privileged type of
   * compression for this field;</li>
   * <li>both the previous and new value are suitable for the JSON Patch computation
   * (i.e. they are valid JSON representations);</li>
   * <li>the item was subscribed to in MERGE or DISTINCT mode (note that, in case of
   * two-level behavior, this holds for all fields related with second-level items,
   * as these items are in MERGE mode);</li>
   * <li>sending the JSON Patch difference has been evaluated by the Server as more
   * efficient than sending the full new value.</li>
   * </ul>
   * Note that the last condition can be enforced by leveraging the Server's
   * &lt;jsonpatch_min_length&gt; configuration flag, so that the availability of the
   * JSON Patch form would only depend on the Client and the Data Adapter.
   * <BR>When the above conditions are not met, the method just returns null; in this
   * case, the new value can only be determined through [ItemUpdate.getValue]. For instance,
   * this will always be needed to get the first value received.
   * 
   * **Throws** IllegalArgumentException if the specified field is not
   * part of the Subscription.
   * 
   * - [fieldName] The field name as specified within the "Field List".
   * 
   * **Returns** A JSON Patch structure representing the difference between
   * the new value and the previous one, or null if the difference in JSON Patch format
   * is not available for any reason.
   * 
   * - See [ItemUpdate.getValue]
   */
  String? getValueAsJSONPatchIfAvailable(String fieldName) {
    return _jsonFields[fieldName];
  }

  /**
   * Inquiry method that gets the difference between the new value and the previous one
   * as a JSON Patch structure, provided that the Server has used the JSON Patch format
   * to send this difference, as part of the "delta delivery" mechanism.
   * 
   * This, in turn, requires that:<ul>
   * <li>the Data Adapter has explicitly indicated JSON Patch as the privileged type of
   * compression for this field;</li>
   * <li>both the previous and new value are suitable for the JSON Patch computation
   * (i.e. they are valid JSON representations);</li>
   * <li>the item was subscribed to in MERGE or DISTINCT mode (note that, in case of
   * two-level behavior, this holds for all fields related with second-level items,
   * as these items are in MERGE mode);</li>
   * <li>sending the JSON Patch difference has been evaluated by the Server as more
   * efficient than sending the full new value.</li>
   * </ul>
   * Note that the last condition can be enforced by leveraging the Server's
   * &lt;jsonpatch_min_length&gt; configuration flag, so that the availability of the
   * JSON Patch form would only depend on the Client and the Data Adapter.
   * <BR>When the above conditions are not met, the method just returns null; in this
   * case, the new value can only be determined through [ItemUpdate.getValue]. For instance,
   * this will always be needed to get the first value received.
   * 
   * **Throws** IllegalArgumentException if the specified field is not
   * part of the Subscription.
   * 
   * - [fieldPosition] The 1-based position of the field within the "Field List" or "Field Schema".
   * 
   * **Returns** A JSON Patch structure representing the difference between
   * the new value and the previous one, or null if the difference in JSON Patch format
   * is not available for any reason.
   * 
   * - See [ItemUpdate.getValue]
   */
  String? getValueAsJSONPatchIfAvailableByPosition(int fieldPosition) {
    return _jsonFieldsByPosition[fieldPosition];
  }

  /**
   * Returns an immutable Map containing the values for each field changed with the last server update. 
   * 
   * The related field name is used as key for the values in the map. 
   * Note that if the Subscription mode of the involved Subscription is COMMAND, then changed fields 
   * are meant as relative to the previous update for the same key. On such tables if a DELETE command 
   * is received, all the fields, excluding the key field, will be present as changed, with null value. 
   * All of this is also true on tables that have the two-level behavior enabled, but in case of 
   * DELETE commands second-level fields will not be iterated.
   * 
   * **Throws** IllegalStateException if the Subscription was initialized using a field schema.
   * 
   * **Returns** An immutable Map containing the values for each field changed with the last server update.
   * 
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  Map<String,String?> getChangedFields() {
    return {..._changedFields};
  }

  /**
   * Returns an immutable Map containing the values for each field changed with the last server update. 
   * 
   * The 1-based field position within the field schema or field list is used as key for the values in the map. 
   * Note that if the Subscription mode of the involved Subscription is COMMAND, then changed fields 
   * are meant as relative to the previous update for the same key. On such tables if a DELETE command 
   * is received, all the fields, excluding the key field, will be present as changed, with null value. 
   * All of this is also true on tables that have the two-level behavior enabled, but in case of 
   * DELETE commands second-level fields will not be iterated.
   * 
   * **Returns** An immutable Map containing the values for each field changed with the last server update.
   * 
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  Map<int,String?> getChangedFieldsByPosition() {
    return {..._changedFieldsByPosition};
  }

  /**
   * Returns an immutable Map containing the values for each field in the Subscription.
   * 
   * The related field name is used as key for the values in the map. 
   * 
   * **Throws** IllegalStateException if the Subscription was initialized using a field schema.
   * 
   * **Returns** An immutable Map containing the values for each field in the Subscription.
   * 
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  Map<String,String?> getFields() {
    return {..._fields};
  }

  /**
   * Returns an immutable Map containing the values for each field in the Subscription.
   * 
   * The 1-based field position within the field schema or field list is used as key for the values in the map. 
   * 
   * **Returns** An immutable Map containing the values for each field in the Subscription.
   * 
   * - See [Subscription.setFieldSchema]
   * - See [Subscription.setFields]
   */
  Map<int,String?> getFieldsByPosition() {
    return {..._fieldsByPosition};
  }
}