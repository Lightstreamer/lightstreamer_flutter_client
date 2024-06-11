package com.lightstreamer.lightstreamer_flutter_client;

import android.os.Handler;
import android.os.Looper;

import com.lightstreamer.client.ClientMessageListener;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyClientMessageLisener implements ClientMessageListener {

    private BasicMessageChannel<String> _messages_channel;
    final String msgId;

    public MyClientMessageLisener(BasicMessageChannel<String> messagestatus_channel, String msgId) {

        _messages_channel = messagestatus_channel;
        this.msgId = msgId;
    }

    @Override
    public void onAbort(final String originalMessage, boolean sentOnNetwork) {
        if (sentOnNetwork) {
            try {
                String json = toJson(new StringBuilder().append("Abort:Sent:").append(originalMessage).toString());
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        _messages_channel.send(json);
                    }
                });

            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }
        } else {
            try {
                String json = toJson(new StringBuilder().append("Abort:NotSent:").append(originalMessage).toString());
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        _messages_channel.send(json);
                    }
                });

            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }
        }

    }

    @Override
    public void onDeny(final String originalMessage, final int code, final String error) {
        try {
            String json = toJson(new StringBuilder().append("Deny:").append(code).append(":").append(error).append(":").append(originalMessage).toString());
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onDiscarded(final String originalMessage) {
        try {
            String json = toJson(new StringBuilder().append("Discarded:").append(originalMessage).toString());
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onError(final String originalMessage) {
        try {
            String json = toJson(new StringBuilder().append("Error:").append(originalMessage).toString());
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onProcessed(final String originalMessage, String response) {
        try {
            String _msg = "Processed:" + originalMessage;
            if (!response.isEmpty()) {
                _msg += "\nResponse:" + response;
            }
            final String msg = _msg;

            String json = toJson(msg);
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(json);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    String toJson(String value) {
        try {
            JSONObject json = new JSONObject();
            json.put("id", msgId);
            json.put("value", value);
            return json.toString();
        } catch (JSONException e) {
            return null;
        }
    }
}
