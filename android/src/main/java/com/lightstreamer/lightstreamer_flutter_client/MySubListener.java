package com.lightstreamer.lightstreamer_flutter_client;

import android.os.Handler;
import android.os.Looper;

import com.lightstreamer.client.SubscriptionListener;
import com.lightstreamer.client.Subscription;
import com.lightstreamer.client.ItemUpdate;

import java.util.Iterator;
import java.util.Map.Entry;

import io.flutter.plugin.common.BasicMessageChannel;

public class MySubListener implements SubscriptionListener {

    private final BasicMessageChannel<String> _subdata_channel;

    private final String _subId;

    private final Subscription sub;
    private Boolean isCommandMode;
    private Boolean hasFieldNames;
    private Integer keyPosition;

    public MySubListener(BasicMessageChannel<String> subdata_channel, String subId, Subscription sub) {
        _subdata_channel = subdata_channel;
        _subId = subId;
        this.sub = sub;
    }

    @Override
    public void onClearSnapshot(final String itemName, final int itemPos) {
        System.out.println("Server has cleared the current status of the chat");

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onClearSnapshot|").append(itemName).append("|").append(itemPos).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onCommandSecondLevelItemLostUpdates(final int lostUpdates, final String key) {
        System.out.println(lostUpdates + " messages were lost for key: " + key);

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onCommandSecondLevelItemLostUpdates|").append(_subId).append("|").append(key).append("|").append(lostUpdates).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onCommandSecondLevelSubscriptionError(final int code, final String message, final String key) {
        System.out.println("Cannot subscribe because of error " + code + ": " + message);

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onCommandSecondLevelSubscriptionError|").append(code).append("|").append(message).append("|").append(key).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR 2nd: " + e.getMessage());
        }
    }

    @Override
    public void onEndOfSnapshot(final String itemName, final int itemPos) {
        System.out.println("Snapshot is now fully received, from now on only real-time messages will be received");

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onEndOfSnapshot|").append(itemName).append("|").append(itemPos).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onItemLostUpdates(final String itemName, final int itemPos, final int lostUpdates) {
        System.out.println(lostUpdates + " messages were lost");

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onItemLostUpdates|").append(_subId).append("|").append(itemName).append("|").append(itemPos).append("|").append(lostUpdates).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onItemUpdate(ItemUpdate update) {
        final String uItem;
        String itemName = update.getItemName() != null ? update.getItemName() : "" + update.getItemPos();
        if (isCommandMode) {
            String keyVal = update.getValue(keyPosition);
            keyVal = keyVal != null ? keyVal : "";
            uItem = itemName + "," + keyVal;
        } else {
            uItem = itemName;
        }

        if (hasFieldNames) {
            for (Entry<String, String> field : update.getChangedFields().entrySet()) {
                final String uKey = field.getKey();
                final String uValue = field.getValue() != null ? field.getValue() : "";
                try {
                    new Handler(Looper.getMainLooper()).post(new Runnable() {
                        @Override
                        public void run() {
                            _subdata_channel.send("onItemUpdate|" + _subId + "|" + uItem + "|" + uKey + "|" + uValue);
                        }
                    });

                } catch (Exception e) {
                    System.out.println("ERROR: " + e.getMessage());
                }
            }
        } else {
            for (Entry<Integer, String> field : update.getChangedFieldsByPosition().entrySet()) {
                final String uKey = "" + field.getKey();
                final String uValue = field.getValue() != null ? field.getValue() : "";
                try {
                    new Handler(Looper.getMainLooper()).post(new Runnable() {
                        @Override
                        public void run() {
                            _subdata_channel.send("onItemUpdate|" + _subId + "|" + uItem + "|" + uKey + "|" + uValue);
                        }
                    });

                } catch (Exception e) {
                    System.out.println("ERROR: " + e.getMessage());
                }
            }
        }
    }

    @Override
    public void onListenEnd() {
        System.out.println("Stop listeneing to subscription events");
    }

    @Override
    public void onListenStart() {
        System.out.println("Start listeneing to subscription events");
    }

    @Override
    public void onSubscription() {
        this.isCommandMode = "COMMAND".equals(sub.getMode());
        this.hasFieldNames = sub.getFields() != null;
        this.keyPosition = sub.getKeyPosition();
    }

    @Override
    public void onSubscriptionError(final int code, final String message) {
        System.out.println("Cannot subscribe because of error " + code + ": " + message);

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _subdata_channel.send(new StringBuilder().append("onSubscriptionError|").append(code).append("|").append(message).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onUnsubscription() {
        System.out.println("Now unsubscribed from chat item, no more messages will be received");
    }

    @Override
    public void onRealMaxFrequency(String frequency) {
        System.out.println("Frequency is " + frequency);
    }
}
