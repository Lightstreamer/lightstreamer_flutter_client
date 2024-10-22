import 'package:lightstreamer_flutter_client/src/client.dart';

/**
 * Interface to be implemented to listen to [LightstreamerClient] events comprehending notifications of 
 * connection activity and errors.
 * 
 * Events for these listeners are dispatched by a different thread than the one that generates them. 
 * This means that, upon reception of an event, it is possible that the internal state of the client has changed.
 * On the other hand, all the notifications for a single LightstreamerClient, including notifications to
 * [ClientListener]s, [SubscriptionListener]s and [ClientMessageListener]s will be dispatched by the 
 * same thread.
 */
class ClientListener {
  /**
   * Event handler that receives a notification each time the LightstreamerClient status has changed. 
   * 
   * The status changes 
   * may be originated either by custom actions (e.g. by calling [LightstreamerClient.disconnect]) or by internal 
   * actions.
   * The normal cases are the following:
   * <ul>
   *   <li>After issuing connect() when the current status is "DISCONNECTED*", the client will switch to "CONNECTING" 
   *       first and to "CONNECTED:STREAM-SENSING" as soon as the pre-flight request receives its answer.<BR> 
   *       As soon as the new session is established, it will switch to "CONNECTED:WS-STREAMING" if the environment 
   *       permits WebSockets; otherwise it will switch to "CONNECTED:HTTP-STREAMING" if the environment permits streaming 
   *       or to "CONNECTED:HTTP-POLLING" as a last resort.</li>
   *   <li>On the other hand, after issuing connect when the status is already "CONNECTED:*" a switch to "CONNECTING"
   *       is usually not needed and the current session is kept.</li>
   *   <li>After issuing [LightstreamerClient.disconnect], the status will switch to "DISCONNECTED".</li>
   *   <li>In case of a server connection refusal, the status may switch from "CONNECTING" directly to "DISCONNECTED". 
   *       After that, the [onServerError] event handler will be invoked.</li>
   * </ul>
   * Possible special cases are the following:
   * <ul>
   *   <li>In case of Server unavailability during streaming, the status may switch from "CONNECTED:*-STREAMING" 
   *       to "STALLED" (see [ConnectionOptions.setStalledTimeout]). If the unavailability ceases, the status 
   *       will switch back to "CONNECTED:*-STREAMING"; otherwise, if the unavailability persists 
   *       (see [ConnectionOptions.setReconnectTimeout]), the status will switch to "DISCONNECTED:TRYING-RECOVERY"
   *       and eventually to "CONNECTED:*-STREAMING".</li>
   *   <li>In case the connection or the whole session is forcibly closed by the Server, the status may switch 
   *       from "CONNECTED:*-STREAMING" or "CONNECTED:*-POLLING" directly to "DISCONNECTED". After that, 
   *       the [onServerError] event handler will be invoked.</li>
   *   <li>Depending on the setting in [ConnectionOptions.setSlowingEnabled], in case of slow update processing, 
   *       the status may switch from "CONNECTED:WS-STREAMING" to "CONNECTED:WS-POLLING" or from "CONNECTED:HTTP-STREAMING" 
   *       to "CONNECTED:HTTP-POLLING".</li>
   *   <li>If the status is "CONNECTED:*-POLLING" and any problem during an intermediate poll occurs, the status may 
   *       switch to "CONNECTING" and eventually to "CONNECTED:*-POLLING". The same may hold for the "CONNECTED:*-STREAMING" case, 
   *       when a rebind is needed.</li>
   *   <li>In case a forced transport was set through [ConnectionOptions.setForcedTransport], only the 
   *       related final status or statuses are possible.</li>
   *   <li>In case of connection problems, the status may switch from any value
   *       to "DISCONNECTED:WILL-RETRY" (see [ConnectionOptions.setRetryDelay]),
   *       then to "CONNECTING" and a new attempt will start.
   *       However, in most cases, the client will try to recover the current session;
   *       hence, the "DISCONNECTED:TRYING-RECOVERY" status will be entered and the recovery attempt will start.</li>
   *   <li>In case of connection problems during a recovery attempt, the status may stay
   *       in "DISCONNECTED:TRYING-RECOVERY" for long time, while further attempts are made.
   *       If the recovery is no longer possible, the current session will be abandoned
   *       and the status will switch to "DISCONNECTED:WILL-RETRY" before the next attempts.</li>
   * </ul>
   * By setting a custom handler it is possible to perform actions related to connection and disconnection occurrences. 
   * Note that [LightstreamerClient.connect] and [LightstreamerClient.disconnect], as any other method, can 
   * be issued directly from within a handler.
   * 
   * - [status] The new status. It can be one of the following values:
   * <ul>
   *   <li>"CONNECTING" the client has started a connection attempt and is waiting for a Server answer.</li>
   *   <li>"CONNECTED:STREAM-SENSING" the client received a first response from the server and is now evaluating if 
   *   a streaming connection is fully functional.</li>
   *   <li>"CONNECTED:WS-STREAMING" a streaming connection over WebSocket has been established.</li>
   *   <li>"CONNECTED:HTTP-STREAMING" a streaming connection over HTTP has been established.</li>
   *   <li>"CONNECTED:WS-POLLING" a polling connection over WebSocket has been started. Note that, unlike polling over 
   *   HTTP, in this case only one connection is actually opened (see [ConnectionOptions.setSlowingEnabled]).</li>
   *   <li>"CONNECTED:HTTP-POLLING" a polling connection over HTTP has been started.</li>
   *   <li>"STALLED" a streaming session has been silent for a while, the status will eventually return to its previous 
   *   CONNECTED:*-STREAMING status or will switch to "DISCONNECTED:WILL-RETRY" / "DISCONNECTED:TRYING-RECOVERY".</li>
   *   <li>"DISCONNECTED:WILL-RETRY" a connection or connection attempt has been closed; a new attempt will be 
   *   performed (possibly after a timeout).</li>
   *   <li>"DISCONNECTED:TRYING-RECOVERY" a connection has been closed and
   *   the client has started a connection attempt and is waiting for a Server answer;
   *   if successful, the underlying session will be kept.</li>
   *   <li>"DISCONNECTED" a connection or connection attempt has been closed. The client will not connect anymore until 
   *   a new [LightstreamerClient.connect] call is issued.</li>
   * </ul>
   *   
   * @see [LightstreamerClient.connect]
   * @see [LightstreamerClient.disconnect]
   * @see [LightstreamerClient.getStatus]
   */
  void onStatusChange(String status) {}
  /**
   * Event handler that receives a notification each time  the value of a property of 
   * [LightstreamerClient.connectionDetails] or [LightstreamerClient.connectionOptions] 
   * is changed.
   * 
   * Properties of these objects can be modified by direct calls to them or
   * by server sent events.
   * 
   * - [property] the name of the changed property.
   * <BR>Possible values are:
   * <ul>
   * <li>adapterSet</li>
   * <li>serverAddress</li>
   * <li>user</li>
   * <li>password</li>
   * <li>contentLength</li>
   * <li>requestedMaxBandwidth</li>
   * <li>reverseHeartbeatInterval</li>
   * <li>httpExtraHeaders</li>
   * <li>httpExtraHeadersOnSessionCreationOnly</li>
   * <li>forcedTransport</li>
   * <li>retryDelay</li>
   * <li>firstRetryMaxDelay</li>
   * <li>sessionRecoveryTimeout</li>
   * <li>stalledTimeout</li>
   * <li>reconnectTimeout</li>
   * <li>slowingEnabled</li>
   * <li>serverInstanceAddressIgnored</li>
   * <li>cookieHandlingRequired</li>
   * <li>proxy</li>
   * <li>serverInstanceAddress</li>
   * <li>serverSocketName</li>
   * <li>clientIp</li>
   * <li>sessionId</li>
   * <li>realMaxBandwidth</li>
   * <li>idleTimeout</li>
   * <li>keepaliveInterval</li>
   * <li>pollingInterval</li>
   * </ul>
   * 
   * @see [LightstreamerClient.connectionDetails]
   * @see [LightstreamerClient.connectionOptions]
   */
  void onPropertyChange(String property) {}
  /**
   * Event handler that is called when the Server notifies a refusal on the client attempt to open
   * a new connection or the interruption of a streaming connection.
   * 
   * In both cases, the [onStatusChange] event handler has already been invoked
   * with a "DISCONNECTED" status and no recovery attempt has been performed.
   * By setting a custom handler, however, it is possible to override this and perform custom recovery actions.
   * 
   * - [errorCode] The error code. It can be one of the following:
   * <ul>
   *   <li>1 - user/password check failed</li>
   *   <li>2 - requested Adapter Set not available</li>
   *   <li>7 - licensed maximum number of sessions reached (this can only happen with some licenses)</li>
   *   <li>8 - configured maximum number of sessions reached</li>
   *   <li>9 - configured maximum server load reached</li>
   *   <li>10 - new sessions temporarily blocked</li>
   *   <li>11 - streaming is not available because of Server license restrictions (this can only happen with special licenses).</li>
   *   <li>21 - a request for this session has unexpectedly reached a wrong Server instance, which suggests that a routing issue may be in place.</li>
   *   <li>30-41 - the current connection or the whole session has been closed by external agents; the possible cause may be:
   *     <ul>
   *       <li>The session was closed on the Server side (via software or by the administrator) (32),
   *           or through a client "destroy" request (31);</li>
   *       <li>The Metadata Adapter imposes limits on the overall open sessions for the current user and has requested 
   *           the closure of the current session upon opening of a new session for the same user on a different browser 
   *           window (35);</li>
   *       <li>An unexpected error occurred on the Server while the session was in activity (33, 34);</li>
   *       <li>An unknown or unexpected cause; any code different from the ones identified in the above cases could be 
   *           issued. A detailed description for the specific cause is currently not supplied (i.e. errorMessage is 
   *           null in this case).</li>
   *   </ul>
   *   <li>60 - this version of the client is not allowed by the current license terms.</li>
   *   <li>61 - there was an error in the parsing of the server response thus the client cannot continue with the current session.</li>
   *   <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection.</li>
   *   <li>68 - the Server could not open or continue with the session because of an internal error.</li>
   *   <li>70 - an unusable port was configured on the server address.</li>
   *   <li>71 - this kind of client is not allowed by the current license terms.</li>
   *   <li>&lt;= 0 - the Metadata Adapter has refused the user connection; the code value is dependent on the specific 
   *       Metadata Adapter implementation</li>
   * </ul>
   * 
   * - [errorMessage] The description of the error as sent by the Server.
   * 
   * @see [onStatusChange]
   * @see [ConnectionDetails.setAdapterSet]
   */
  void onServerError(int errorCode, String errorMessage) {}
  /**
   * Event handler that receives a notification when the ClientListener instance is removed from a LightstreamerClient 
   * through [LightstreamerClient.removeListener]. 
   * 
   * This is the last event to be fired on the listener.
   */
  void onListenEnd() {}
  /**
   * Event handler that receives a notification when the ClientListener instance is added to a LightstreamerClient 
   * through [LightstreamerClient.addListener]. 
   * 
   * This is the first event to be fired on the listener.
   */
  void onListenStart() {}
}

/**
 * Interface to be implemented to listen to [Subscription] events comprehending notifications of subscription/unsubscription, 
 * updates, errors and others.
 * 
 * Events for these listeners are dispatched by a different thread than the one that generates them. 
 * This means that, upon reception of an event, it is possible that the internal state of the client has changed.
 * On the other hand, all the notifications for a single LightstreamerClient, including notifications to
 * [ClientListener]s, [SubscriptionListener]s and [ClientMessageListener]s will be dispatched by the 
 * same thread.
 */
class SubscriptionListener {
  /**
   * Event handler that is called by Lightstreamer each time a request to clear the snapshot pertaining to an item 
   * in the Subscription has been received from the Server. 
   * 
   * More precisely, this kind of request can occur in two cases:
   * <ul>
   *   <li>For an item delivered in COMMAND mode, to notify that the state of the item becomes empty; this is 
   *       equivalent to receiving an update carrying a DELETE command once for each key that is currently active.</li>
   *   <li>For an item delivered in DISTINCT mode, to notify that all the previous updates received for the item 
   *       should be considered as obsolete; hence, if the listener were showing a list of recent updates for the item, it 
   *       should clear the list in order to keep a coherent view.</li>
   * </ul>
   * Note that, if the involved Subscription has a two-level behavior enabled
   * (see [Subscription.setCommandSecondLevelFields] and [Subscription.setCommandSecondLevelFieldSchema])
   * , the notification refers to the first-level item (which is in COMMAND mode).
   * This kind of notification is not possible for second-level items (which are in MERGE 
   * mode).
   * 
   * - [itemName] name of the involved item. If the Subscription was initialized using an "Item Group" then a 
   *        null value is supplied.
   * - [itemPos] 1-based position of the item within the "Item List" or "Item Group".
   */
  void onClearSnapshot(String itemName, int itemPos) {}
  /**
   * Event handler that is called by Lightstreamer to notify that, due to internal resource limitations, 
   * Lightstreamer Server dropped one or more updates for an item that was subscribed to as a second-level subscription. 
   * 
   * Such notifications are sent only if the Subscription was configured in unfiltered mode (second-level items are 
   * always in "MERGE" mode and inherit the frequency configuration from the first-level Subscription). <BR> 
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [lostUpdates] The number of consecutive updates dropped for the item.
   * - [key] The value of the key that identifies the second-level item.
   * 
   * @see [Subscription.setRequestedMaxFrequency]
   * @see [Subscription.setCommandSecondLevelFields]
   * @see [Subscription.setCommandSecondLevelFieldSchema]
   */
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {}
  /**
   * Event handler that is called when the Server notifies an error on a second-level subscription.
   * 
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [errorCode] The error code sent by the Server. It can be one of the following:
   *        <ul>
   *          <li>14 - the key value is not a valid name for the Item to be subscribed; only in this case, the error 
   *              is detected directly by the library before issuing the actual request to the Server</li>
   *          <li>17 - bad Data Adapter name or default Data Adapter not defined for the current Adapter Set</li>
   *          <li>21 - bad Group name</li>
   *          <li>22 - bad Group name for this Schema</li>
   *          <li>23 - bad Schema name</li>
   *          <li>24 - mode not allowed for an Item</li>
   *          <li>26 - unfiltered dispatching not allowed for an Item, because a frequency limit is associated 
   *              to the item</li>
   *          <li>27 - unfiltered dispatching not supported for an Item, because a frequency prefiltering is 
   *              applied for the item</li>
   *          <li>28 - unfiltered dispatching is not allowed by the current license terms (for special licenses 
   *              only)</li>
   *          <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection</li>
   *          <li>68 - the Server could not fulfill the request because of an internal error.</li>
   *          <li>&lt;= 0 - the Metadata Adapter has refused the subscription or unsubscription request; the 
   *              code value is dependent on the specific Metadata Adapter implementation</li>
   *        </ul>
   *
   * - [errorMessage] The description of the error sent by the Server; it can be null.
   * - [key] The value of the key that identifies the second-level item.
   * 
   * @see [ConnectionDetails.setAdapterSet]
   * @see [Subscription.setCommandSecondLevelFields]
   * @see [Subscription.setCommandSecondLevelFieldSchema]
   */
  void onCommandSecondLevelSubscriptionError(int errorCode, String errorMessage, String key) {}
  /**
   * Event handler that is called by Lightstreamer to notify that all snapshot events for an item in the 
   * Subscription have been received, so that real time events are now going to be received. 
   * 
   * The received snapshot could be empty. Such notifications are sent only if the items are delivered in DISTINCT or COMMAND 
   * subscription mode and snapshot information was indeed requested for the items. By implementing this 
   * method it is possible to perform actions which require that all the initial values have been received. <BR>
   * Note that, if the involved Subscription has a two-level behavior enabled
   * (see [Subscription.setCommandSecondLevelFields] and [Subscription.setCommandSecondLevelFieldSchema])
   * , the notification refers to the first-level item (which is in COMMAND mode).
   * Snapshot-related updates for the second-level items 
   * (which are in MERGE mode) can be received both before and after this notification.
   * 
   * - [itemName] name of the involved item. If the Subscription was initialized using an "Item Group" then a 
   *        null value is supplied.
   * - [itemPos] 1-based position of the item within the "Item List" or "Item Group".
   * 
   * @see [Subscription.setRequestedSnapshot]
   * @see [ItemUpdate.isSnapshot]
   */
  void onEndOfSnapshot(String itemName, int itemPos) {}
  /**
   * Event handler that is called by Lightstreamer to notify that, due to internal resource limitations, 
   * Lightstreamer Server dropped one or more updates for an item in the Subscription. 
   * 
   * Such notifications are sent only if the items are delivered in an unfiltered mode; this occurs if the 
   * subscription mode is:
   * <ul>
   *   <li>RAW</li>
   *   <li>MERGE or DISTINCT, with unfiltered dispatching specified</li>
   *   <li>COMMAND, with unfiltered dispatching specified</li>
   *   <li>COMMAND, without unfiltered dispatching specified (in this case, notifications apply to ADD 
   *       and DELETE events only)</li>
   * </ul>
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [itemName] name of the involved item. If the Subscription was initialized using an "Item Group" then a 
   *        null value is supplied.
   * - [itemPos] 1-based position of the item within the "Item List" or "Item Group".
   * - [lostUpdates] The number of consecutive updates dropped for the item.
   * 
   * @see [Subscription.setRequestedMaxFrequency]
   */
  void onItemLostUpdates(String itemName, int itemPos, int lostUpdates) {}
  /**
   * Event handler that is called by Lightstreamer each time an update pertaining to an item in the Subscription
   * has been received from the Server.
   * 
   * - [update] a value object containing the updated values for all the fields, together with meta-information 
   * about the update itself and some helper methods that can be used to iterate through all or new values.
   */
  void onItemUpdate(ItemUpdate update) {}
  /**
   * Event handler that receives a notification when the SubscriptionListener instance is removed from a Subscription 
   * through [Subscription.removeListener]. 
   * 
   * This is the last event to be fired on the listener.
   */
  void onListenEnd() {}
  /**
   * Event handler that receives a notification when the SubscriptionListener instance is added to a Subscription 
   * through [Subscription.addListener]. 
   * 
   * This is the first event to be fired on the listener.
   */
  void onListenStart() {}
  /**
   * Event handler that is called by Lightstreamer to notify the client with the real maximum update frequency of the Subscription. 
   * 
   * It is called immediately after the Subscription is established and in response to a requested change
   * (see [Subscription.setRequestedMaxFrequency]).
   * Since the frequency limit is applied on an item basis and a Subscription can involve multiple items,
   * this is actually the maximum frequency among all items. For Subscriptions with two-level behavior
   * (see [Subscription.setCommandSecondLevelFields] and [Subscription.setCommandSecondLevelFieldSchema])
   * , the reported frequency limit applies to both first-level and second-level items. <BR>
   * The value may differ from the requested one because of restrictions operated on the server side,
   * but also because of number rounding. <BR>
   * Note that a maximum update frequency (that is, a non-unlimited one) may be applied by the Server
   * even when the subscription mode is RAW or the Subscription was done with unfiltered dispatching.
   * 
   * - [frequency]  A decimal number, representing the maximum frequency applied by the Server
   * (expressed in updates per second), or the string "unlimited". A null value is possible in rare cases,
   * when the frequency can no longer be determined.
   */
  void onRealMaxFrequency(String? frequency) {}
  /**
   * Event handler that is called by Lightstreamer to notify that a Subscription has been successfully subscribed 
   * to through the Server. 
   * 
   * This can happen multiple times in the life of a Subscription instance, in case the 
   * Subscription is performed multiple times through [LightstreamerClient.unsubscribe] and 
   * [LightstreamerClient.subscribe]. This can also happen multiple times in case of automatic 
   * recovery after a connection restart. <BR> 
   * This notification is always issued before the other ones related to the same subscription. It invalidates all 
   * data that has been received previously. <BR>
   * Note that two consecutive calls to this method are not possible, as before a second onSubscription event is 
   * fired an [onUnsubscription] event is eventually fired. <BR> 
   * If the involved Subscription has a two-level behavior enabled
   * (see [Subscription.setCommandSecondLevelFields] and [Subscription.setCommandSecondLevelFieldSchema])
   * , second-level subscriptions are not notified.
   */
  void onSubscription() {}
  /**
   * Event handler that is called when the Server notifies an error on a Subscription. By implementing this method it 
   * is possible to perform recovery actions.
   * 
   * Note that, in order to perform a new subscription attempt, [LightstreamerClient.unsubscribe]
   * and [LightstreamerClient.subscribe] should be issued again, even if no change to the Subscription 
   * attributes has been applied.
   *
   * - [errorCode] The error code sent by the Server. It can be one of the following:
   *        <ul>
   *          <li>15 - "key" field not specified in the schema for a COMMAND mode subscription</li>
   *          <li>16 - "command" field not specified in the schema for a COMMAND mode subscription</li>
   *          <li>17 - bad Data Adapter name or default Data Adapter not defined for the current Adapter Set</li>
   *          <li>21 - bad Group name</li>
   *          <li>22 - bad Group name for this Schema</li>
   *          <li>23 - bad Schema name</li>
   *          <li>24 - mode not allowed for an Item</li>
   *          <li>25 - bad Selector name</li>
   *          <li>26 - unfiltered dispatching not allowed for an Item, because a frequency limit is associated 
   *              to the item</li>
   *          <li>27 - unfiltered dispatching not supported for an Item, because a frequency prefiltering is 
   *              applied for the item</li>
   *          <li>28 - unfiltered dispatching is not allowed by the current license terms (for special licenses 
   *              only)</li>
   *          <li>29 - RAW mode is not allowed by the current license terms (for special licenses only)</li>
   *          <li>30 - subscriptions are not allowed by the current license terms (for special licenses only)</li>
   *          <li>61 - there was an error in the parsing of the server response</li>
   *          <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection</li>
   *          <li>68 - the Server could not fulfill the request because of an internal error.</li>
   *          <li>&lt;= 0 - the Metadata Adapter has refused the subscription or unsubscription request; the 
   *              code value is dependent on the specific Metadata Adapter implementation</li>
   *        </ul>
   *
   * - [errorMessage] The description of the error sent by the Server; it can be null.
   * 
   * @see [ConnectionDetails.setAdapterSet]
   */
  void onSubscriptionError(int errorCode, String errorMessage) {}
  /**
   * Event handler that is called by Lightstreamer to notify that a Subscription has been successfully unsubscribed 
   * from. 
   * 
   * This can happen multiple times in the life of a Subscription instance, in case the Subscription is performed 
   * multiple times through [LightstreamerClient.unsubscribe] and 
   * [LightstreamerClient.subscribe]. This can also happen multiple times in case of automatic 
   * recovery after a connection restart. <BR>
   * After this notification no more events can be received until a new [onSubscription] event. <BR> 
   * Note that two consecutive calls to this method are not possible, as before a second onUnsubscription event 
   * is fired an [onSubscription] event is eventually fired. <BR> 
   * If the involved Subscription has a two-level behavior enabled
   * (see [Subscription.setCommandSecondLevelFields] and [Subscription.setCommandSecondLevelFieldSchema])
   * , second-level unsubscriptions are not notified.
   */
  void onUnsubscription() {}
}

/**
 * Interface to be implemented to listen to [LightstreamerClient.sendMessage] events reporting a message processing outcome. 
 * 
 * Events for these listeners are dispatched by a different thread than the one that generates them.
 * All the notifications for a single LightstreamerClient, including notifications to
 * [ClientListener]s, [SubscriptionListener]s and [ClientMessageListener]s will be dispatched by the 
 * same thread.
 * Only one event per message is fired on this listener.
 */
class ClientMessageListener {
  /**
   * Event handler that is called by Lightstreamer when any notifications of the processing outcome of the related 
   * message haven't been received yet and can no longer be received. 
   * 
   * Typically, this happens after the session 
   * has been closed. In this case, the client has no way of knowing the processing outcome and any outcome is possible.
   * - [originalMessage] the message to which this notification is related.
   * - [sentOnNetwork] true if the message was sent on the network, false otherwise. 
   *        Even if the flag is true, it is not possible to infer whether the message actually reached the 
   *        Lightstreamer Server or not.
   */
  void onAbort(String originalMessage, bool sentOnNetwork) {}
  /**
   * Event handler that is called by Lightstreamer when the related message has been processed by the Server but the 
   * expected processing outcome could not be achieved for any reason.
   * 
   * - [originalMessage] the message to which this notification is related.
   * - [errorCode] the error code sent by the Server. It can be one of the following:
   *        <ul><li>&lt;= 0 - the Metadata Adapter has refused the message; the code value is dependent on the 
   *        specific Metadata Adapter implementation.</li></ul>
   * - [errorMessage] the description of the error sent by the Server.
   */
  void onDeny(String originalMessage, int errorCode, String errorMessage) {}
  /**
   * Event handler that is called by Lightstreamer to notify that the related message has been discarded by the Server.
   * 
   * This means that the message has not reached the Metadata Adapter and the message next in the sequence is considered 
   * enabled for processing.
   * - [originalMessage] the message to which this notification is related.
   */
  void onDiscarded(String originalMessage) {}
  /**
   * Event handler that is called by Lightstreamer when the related message has been processed by the Server but the 
   * processing has failed for any reason. 
   * 
   * The level of completion of the processing by the Metadata Adapter cannot be 
   * determined.
   * - [originalMessage] the message to which this notification is related.
   */
  void onError(String originalMessage) {}
  /**
   * Event handler that is called by Lightstreamer when the related message has been processed by the Server with success.
   * 
   * - [originalMessage] the message to which this notification is related.
   * - [response] the response from the Metadata Adapter. If not supplied (i.e. supplied as null), an empty message is received here.
   */
  void onProcessed(String originalMessage, String response) {}
}

/**
 * Interface to be implemented to receive MPN device events including registration, suspension/resume and status change.
 * 
 * Events for these listeners are dispatched by a different thread than the one that generates them. This means that, upon reception of an event,
 * it is possible that the internal state of the client has changed. On the other hand, all the notifications for a single [LightstreamerClient], including
 * notifications to [ClientListener], [SubscriptionListener], [ClientMessageListener], [MpnDeviceListener] and [MpnSubscriptionListener]
 * will be dispatched by the same thread.
 */
class MpnDeviceListener {
  /**
   * Event handler called when the MpnDeviceListener instance is removed from an MPN device object through [MpnDevice.removeListener].
   * 
   * This is the last event to be fired on the listener.
   */
  void onListenEnd() {}
  /**
   * Event handler called when the MpnDeviceListener instance is added to an MPN device object through [MpnDevice.addListener].
   * 
   * This is the first event to be fired on the listener.
   */
  void onListenStart() {}
  /**
   * Event handler called when an MPN device object has been successfully registered on the server's MPN Module.
   * 
   * This event handler is always called before other events related to the same device.<BR>
   * Note that this event can be called multiple times in the life of an MPN device object in case the client disconnects and reconnects. In this case
   * the device is registered again automatically.
   */
  void onRegistered() {}
  /**
   * Event handler called when the server notifies an error while registering an MPN device object.
   * 
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [errorCode] The error code sent by the Server. It can be one of the following:<ul>
   * <li>40 - the MPN Module is disabled, either by configuration or by license restrictions.</li>
   * <li>41 - the request failed because of some internal resource error (e.g. database connection, timeout, etc.).</li>
   * <li>43 - invalid or unknown application ID.</li>
   * <li>45 - invalid or unknown MPN device ID.</li>
   * <li>48 - MPN device suspended.</li>
   * <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection.</li>
   * <li>68 - the Server could not fulfill the request because of an internal error.</li>
   * <li>&lt;= 0 - the Metadata Adapter has refused the subscription request; the code value is dependent on the specific Metadata Adapter implementation.</li>
   * </ul>
   * - [errorMessage] The description of the error sent by the Server; it can be null.
   */
  void onRegistrationFailed(int errorCode, String errorMessage) {}
  /**
   * Event handler called when an MPN device object has been resumed on the server's MPN Module.
   * 
   * An MPN device may be resumed from suspended state at the first subsequent registration.<BR>
   * Note that in some server clustering configurations this event may not be called.
   */
  void onResumed() {}
  /**
   * Event handler called when the server notifies that an MPN device changed its status.
   * 
   * Note that in some server clustering configurations the status change for the MPN device suspend event may not be called.
   * 
   * - [status] The new status of the MPN device. It can be one of the following:<ul>
   * <li><code>UNKNOWN</code></li>
   * <li><code>REGISTERED</code></li>
   * <li><code>SUSPENDED</code></li>
   * </ul>
   * - [timestamp] The server-side timestamp of the new device status.
   * 
   * @see [MpnDevice.getStatus]
   * @see [MpnDevice.getStatusTimestamp]
   */
  void onStatusChanged(String status, int timestamp) {}
  /**
   * Event handler called when the server notifies that the list of MPN subscription associated with an MPN device has been updated.
   * 
   * After registration, the list of pre-existing MPN subscriptions for the MPN device is updated and made available through the
   * [LightstreamerClient.getMpnSubscriptions] method.
   * 
   * @see [LightstreamerClient.getMpnSubscriptions]
   */
  void onSubscriptionsUpdated() {}
  /**
   * Event handler called when an MPN device object has been suspended on the server's MPN Module.
   * 
   * An MPN device may be suspended if errors occur during push notification delivery.<BR>
   * Note that in some server clustering configurations this event may not be called.
   */
  void onSuspended() {}
}

/**
 * Interface to be implemented to receive [MpnSubscription] events including subscription/unsubscription, triggering and status change.
 * 
 * Events for these listeners are dispatched by a different thread than the one that generates them. This means that, upon reception of an event,
 * it is possible that the internal state of the client has changed. On the other hand, all the notifications for a single [LightstreamerClient], including
 * notifications to [ClientListener], [SubscriptionListener], [ClientMessageListener], [MpnDeviceListener] and MpnSubscriptionListener
 * will be dispatched by the same thread.
 */
class MpnSubscriptionListener {
  /**
   * Event handler called when the MpnSubscriptionListener instance is removed from an [MpnSubscription] through 
   * [MpnSubscription.removeListener].
   * 
   * This is the last event to be fired on the listener.
   */
  void onListenEnd() {}
  /**
   * Event handler called when the MpnSubscriptionListener instance is added to an [MpnSubscription] through 
   * [MpnSubscription.addListener].
   * 
   * This is the first event to be fired on the listener.
   */
  void onListenStart() {}
  /**
   * Event handler called when the value of a property of [MpnSubscription] cannot be changed.
   * 
   * Properties can be modified by direct calls to their setters. See [MpnSubscription.setNotificationFormat] and [MpnSubscription.setTriggerExpression].
   * 
   * - [errorCode] The error code sent by the Server.
   * - [errorMessage] The description of the error sent by the Server.
   * - [propertyName] The name of the changed property. It can be one of the following:<ul>
   * <li><code>notification_format</code></li>
   * <li><code>trigger</code></li>
   * </ul>
   */
  void onModificationError(int errorCode, String errorMessage, String propertyName) {}
  /**
   * Event handler called each time the value of a property of [MpnSubscription] is changed.
   * 
   * Properties can be modified by direct calls to their setter or by server sent events. A property may be changed by a server sent event when the MPN subscription is
   * modified, or when two MPN subscriptions coalesce (see [LightstreamerClient.subscribeMpn]).
   * 
   * - [propertyName] The name of the changed property. It can be one of the following:<ul>
   * <li><code>mode</code></li>
   * <li><code>group</code></li>
   * <li><code>schema</code></li>
   * <li><code>adapter</code></li>
   * <li><code>notification_format</code></li>
   * <li><code>trigger</code></li>
   * <li><code>requested_buffer_size</code></li>
   * <li><code>requested_max_frequency</code></li>
   * <li><code>status_timestamp</code></li>
   * </ul>
   */
  void onPropertyChanged(String propertyName) {}
  /**
   * Event handler called when the server notifies that an [MpnSubscription] changed its status.
   * 
   * Note that in some server clustering configurations the status change for the MPN subscription's trigger event may not be called. The corresponding push
   * notification is always sent, though.
   * 
   * - [status] The new status of the MPN subscription. It can be one of the following:<ul>
   * <li><code>UNKNOWN</code></li>
   * <li><code>ACTIVE</code></li>
   * <li><code>SUBSCRIBED</code></li>
   * <li><code>TRIGGERED</code></li>
   * </ul>
   * - [timestamp] The server-side timestamp of the new subscription status.
   * 
   * @see [MpnSubscription.getStatus]
   * @see [MpnSubscription.getStatusTimestamp]
   */
  void onStatusChanged(String status, int timestamp) {}
  /**
   * Event handler called when an [MpnSubscription] has been successfully subscribed to on the server's MPN Module.
   * 
   * This event handler is always called before other events related to the same subscription.<BR>
   * Note that this event can be called multiple times in the life of an MpnSubscription instance only in case it is subscribed multiple times
   * through [LightstreamerClient.unsubscribeMpn] and [LightstreamerClient.subscribeMpn]. Two consecutive calls 
   * to this method are not possible, as before a second <code>onSubscription()</code> event an [onUnsubscription] event is always fired.
   */
  void onSubscription() {}
  /**
   * Event handler called when the server notifies an error while subscribing to an [MpnSubscription].
   * 
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [errorCode] The error code sent by the Server. It can be one of the following:<ul>
   * <li>17 - bad Data Adapter name or default Data Adapter not defined for the current Adapter Set.</li>
   * <li>21 - bad Group name.</li>
   * <li>22 - bad Group name for this Schema.</li>
   * <li>23 - bad Schema name.</li>
   * <li>24 - mode not allowed for an Item.</li>
   * <li>30 - subscriptions are not allowed by the current license terms (for special licenses only).</li>
   * <li>40 - the MPN Module is disabled, either by configuration or by license restrictions.</li>
   * <li>41 - the request failed because of some internal resource error (e.g. database connection, timeout, etc.).</li>
   * <li>43 - invalid or unknown application ID.</li>
   * <li>44 - invalid syntax in trigger expression.</li>
   * <li>45 - invalid or unknown MPN device ID.</li>
   * <li>46 - invalid or unknown MPN subscription ID (for MPN subscription modifications).</li>
   * <li>47 - invalid argument name in notification format or trigger expression.</li>
   * <li>48 - MPN device suspended.</li>
   * <li>49 - one or more subscription properties exceed maximum size.</li>
   * <li>50 - no items or fields have been specified.</li>
   * <li>52 - the notification format is not a valid JSON structure.</li>
   * <li>53 - the notification format is empty.</li>
   * <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection.</li>
   * <li>68 - the Server could not fulfill the request because of an internal error.</li>
   * <li>&lt;= 0 - the Metadata Adapter has refused the subscription request; the code value is dependent on the specific Metadata Adapter implementation.</li>
   * </ul>
   * - [errorMessage] The description of the error sent by the Server; it can be null.
   */
  void onSubscriptionError(int errorCode, String errorMessage) {}
  /**
   * Event handler called when the server notifies that an [MpnSubscription] did trigger.
   * 
   * For this event to be called the MpnSubscription must have a trigger expression set and it must have been evaluated to true at
   * least once.<BR>
   * Note that this event can be called multiple times in the life of an MpnSubscription instance only in case it is subscribed multiple times
   * through [LightstreamerClient.unsubscribeMpn] and [LightstreamerClient.subscribeMpn]. Two consecutive calls 
   * to this method are not possible.<BR>
   * Note also that in some server clustering configurations this event may not be called. The corresponding push notification is always sent, though.
   * 
   * @see [MpnSubscription.setTriggerExpression]
   */
  void onTriggered() {}
  /**
   * Event handler called when an [MpnSubscription] has been successfully unsubscribed from on the server's MPN Module.
   * 
   * After this call no more events can be received until a new [onSubscription] event.<BR>
   * Note that this event can be called multiple times in the life of an MpnSubscription instance only in case it is subscribed multiple times
   * through [LightstreamerClient.unsubscribeMpn] and [LightstreamerClient.subscribeMpn]. Two consecutive calls 
   * to this method are not possible, as before a second [onUnsubscription] event an [onSubscription] event is always fired.
   */
  void onUnsubscription() {}
  /**
   * Event handler called when the server notifies an error while unsubscribing from an [MpnSubscription].
   * 
   * By implementing this method it is possible to perform recovery actions.
   * 
   * - [errorCode] The error code sent by the Server. It can be one of the following:<ul>
   * <li>30 - subscriptions are not allowed by the current license terms (for special licenses only).</li>
   * <li>40 - the MPN Module is disabled, either by configuration or by license restrictions.</li>
   * <li>41 - the request failed because of some internal resource error (e.g. database connection, timeout, etc.).</li>
   * <li>43 - invalid or unknown application ID.</li>
   * <li>45 - invalid or unknown MPN device ID.</li>
   * <li>46 - invalid or unknown MPN subscription ID.</li>
   * <li>48 - MPN device suspended.</li>
   * <li>66 - an unexpected exception was thrown by the Metadata Adapter while authorizing the connection.</li>
   * <li>68 - the Server could not fulfill the request because of an internal error.</li>
   * <li>&lt;= 0 - the Metadata Adapter has refused the unsubscription request; the code value is dependent on the specific Metadata Adapter implementation.</li>
   * </ul>
   * - [errorMessage] The description of the error sent by the Server; it can be null.
   */
  void onUnsubscriptionError(int errorCode, String errorMessage) {}
}