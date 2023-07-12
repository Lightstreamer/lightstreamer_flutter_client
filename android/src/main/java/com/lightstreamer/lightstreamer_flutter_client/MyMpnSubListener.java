package com.lightstreamer.lightstreamer_flutter_client;

import com.lightstreamer.client.mpn.MpnSubscription;
import com.lightstreamer.client.mpn.MpnSubscriptionListener;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyMpnSubListener  implements MpnSubscriptionListener {

    private BasicMessageChannel<String> _subdata_channel;

    private String _subId = "";

    public MyMpnSubListener(BasicMessageChannel<String> subdata_channel, String subId) {
        _subdata_channel = subdata_channel;
        _subId = subId;
    }

    @Override
    public void onListenStart() {

    }

    @Override
    public void onListenEnd() {

    }

    @Override
    public void onSubscription() {

    }

    @Override
    public void onUnsubscription() {

    }

    @Override
    public void onSubscriptionError(int code, String message) {

    }

    @Override
    public void onUnsubscriptionError(int code, String message) {

    }

    @Override
    public void onTriggered() {

    }

    @Override
    public void onStatusChanged(String status, long timestamp) {

    }

    @Override
    public void onPropertyChanged(String propertyName) {

    }

    @Override
    public void onModificationError(int code, String message, String propertyName) {

    }
}
