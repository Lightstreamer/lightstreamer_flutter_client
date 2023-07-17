package com.lightstreamer.lightstreamer_flutter_client;

import android.os.Handler;
import android.os.Looper;

import com.lightstreamer.client.ClientMessageListener;

import io.flutter.plugin.common.BasicMessageChannel;

public class MyClientMessageLisener implements ClientMessageListener {

    private BasicMessageChannel<String> _messages_channel;

    public MyClientMessageLisener(BasicMessageChannel<String> messagestatus_channel) {

        _messages_channel = messagestatus_channel;

    }

    @Override
    public void onAbort(final String originalMessage, boolean sentOnNetwork) {
        if (sentOnNetwork) {
            try {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        _messages_channel.send(new StringBuilder().append("Abort:Sent:").append(originalMessage).toString());
                    }
                });

            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }
        } else {
            try {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        _messages_channel.send(new StringBuilder().append("Abort:NotSent:").append(originalMessage).toString());
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
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(new StringBuilder().append("Deny:").append(code).append(":").append(error).append(":").append(originalMessage).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onDiscarded(final String originalMessage) {
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(new StringBuilder().append("Discarded:").append(originalMessage).toString());
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }

    @Override
    public void onError(final String originalMessage) {
        try {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(new StringBuilder().append("Error:").append(originalMessage).toString());
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
            String msg = _msg;

            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    _messages_channel.send(msg);
                }
            });

        } catch (Exception e) {
            System.out.println("ERROR: " + e.getMessage());
        }
    }
}
