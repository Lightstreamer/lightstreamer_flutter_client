#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint lightstreamer_flutter_client.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'lightstreamer_flutter_client'
  s.version          = '2.1.3'
  s.summary          = 'A Flutter plugin for Lightstreamer.'
  s.homepage         = 'https://github.com/Lightstreamer/lightstreamer_flutter_client'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lightstreamer' => 'support@lightstreamer.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.dependency 'LightstreamerClient', '~> 6.3.0'
end
