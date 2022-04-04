package com.lightstreamer.lightstreamer_flutter_client;

import com.lightstreamer.client.ClientListener;
import com.lightstreamer.client.LightstreamerClient;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyClientListener implements ClientListener {

    private BasicMessageChannel<String> _clientstatus_channel;

    public MyClientListener(BasicMessageChannel<String> clientstatus_channel) {
        _clientstatus_channel = clientstatus_channel;
    }

    @Override
    public void onListenEnd(LightstreamerClient client) {
        // ...
    }

    @Override
    public void onListenStart(LightstreamerClient client) {
        // ...
    }

    @Override
    public void onServerError(int errorCode, String errorMessage) {
        // ...
    }

    @Override
    public void onStatusChange(final String status) {

        System.out.println("Status changed: " + status);
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(status);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onPropertyChange(String property) {
        // ...
    }
}
