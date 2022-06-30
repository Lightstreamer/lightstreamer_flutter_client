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

    private BasicMessageChannel<String> _subdata_channel;

    private String _subId = "";

    public MySubListener(BasicMessageChannel<String> subdata_channel, String subId) {
        _subdata_channel = subdata_channel;
        _subId = subId;
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
    public void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {
        //not on this subscription
    }

    @Override
    public void onCommandSecondLevelSubscriptionError(int code, String message, String key) {
        //not on this subscription
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

        System.out.println("====UPDATE====> " + update.getItemName());

        Iterator<Entry<String,String>> changedValues = update.getChangedFields().entrySet().iterator();
        while(changedValues.hasNext()) {
            Entry<String,String> field = changedValues.next();

            final String uValue = field.getValue();
            final String uKey = field.getKey();
            final String uItem = update.getItemName();

            System.out.println("Field " + uKey + " changed: " + uValue);

            try {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        _subdata_channel.send(new StringBuilder().append("onItemUpdate|").append(_subId).append("|").append(uItem).append("|").append(uKey).append("|").append(uValue).toString());
                    }
                });

            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }

            System.out.println("<====UPDATE====");
        }
    }

    @Override
    public void onListenEnd(Subscription subscription) {
        System.out.println("Stop listeneing to subscription events");
    }

    @Override
    public void onListenStart(Subscription subscription) {
        System.out.println("Start listeneing to subscription events");
    }

    @Override
    public void onSubscription() {
        System.out.println("Now subscribed to the chat item, messages will now start coming in");
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
