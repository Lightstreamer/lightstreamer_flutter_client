import Flutter
import UIKit

public class SwiftLightstreamerFlutterClientPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "lightstreamer_flutter_client", binaryMessenger: registrar.messenger())
    let instance = SwiftLightstreamerFlutterClientPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
