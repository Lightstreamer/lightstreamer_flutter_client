#import "LightstreamerFlutterClientPlugin.h"
#if __has_include(<lightstreamer_flutter_client/lightstreamer_flutter_client-Swift.h>)
#import <lightstreamer_flutter_client/lightstreamer_flutter_client-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "lightstreamer_flutter_client-Swift.h"
#endif

@implementation LightstreamerFlutterClientPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [LightstreamerFlutterPlugin registerWithRegistrar:registrar];
}
@end
