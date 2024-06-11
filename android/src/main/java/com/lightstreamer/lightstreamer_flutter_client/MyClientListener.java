package com.lightstreamer.lightstreamer_flutter_client;

import com.lightstreamer.client.ClientListener;
import com.lightstreamer.client.LightstreamerClient;

import android.os.Handler;
import android.os.Looper;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyClientListener implements ClientListener {

    private BasicMessageChannel<String> _clientstatus_channel;
    final String clientId;

    public MyClientListener(BasicMessageChannel<String> clientstatus_channel, String clientId) {
        _clientstatus_channel = clientstatus_channel;
        this.clientId = clientId;
    }

    @Override
    public void onListenEnd() {
        // ...
    }

    @Override
    public void onListenStart() {
    }

    @Override
    public void onServerError(final int errorCode, final String errorMessage) {
        String json = toJson(new StringBuilder().append("ServerError:").append(errorCode).append(errorMessage).toString());
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onStatusChange(final String status) {
        String json = toJson(new StringBuilder().append("StatusChange:").append(status).toString());
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onPropertyChange(final String property) {
        String json = toJson(new StringBuilder().append("PropertyChange:").append(property).toString());

        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _clientstatus_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    String toJson(String value) {
        try {
            JSONObject json = new JSONObject();
            json.put("id", clientId);
            json.put("value", value);
            return json.toString();
        } catch (JSONException e) {
            return null;
        }
    }
}
