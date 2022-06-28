package com.lightstreamer.lightstreamer_flutter_client;

import com.lightstreamer.client.ClientListener;
import com.lightstreamer.client.LightstreamerClient;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyClientListener implements ClientListener {

    private BasicMessageChannel<String> _clientstatus_channel;

    private LightstreamerClient client;

    public MyClientListener(BasicMessageChannel<String> clientstatus_channel) {
        _clientstatus_channel = clientstatus_channel;
    }

    @Override
    public void onListenEnd(LightstreamerClient client) {
        // ...
    }

    @Override
    public void onListenStart(LightstreamerClient client) {
        this.client = client;
    }

    @Override
    public void onServerError(final int errorCode, final String errorMessage) {
        System.out.println(new StringBuilder().append("Server error ").append(errorCode).append(" :").append(errorMessage).toString());
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(new StringBuilder().append("ServerError:").append(errorCode).append(errorMessage).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onStatusChange(final String status) {
        System.out.println("Status changed: " + status);
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(new StringBuilder().append("StatusChange:").append(status).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onPropertyChange(final String property) {
        System.out.println(new StringBuilder().append("Property Change: ").append(property));

        if (property.equalsIgnoreCase("realMaxBandwidth")) {
            System.out.println(new StringBuilder().append("Real Max Bandwidth: ").append(this.client.connectionOptions.getRealMaxBandwidth()));
        }
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(new StringBuilder().append("PropertyChange:").append(property).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }
}
