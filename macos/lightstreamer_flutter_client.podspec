#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint lightstreamer_flutter_client.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'lightstreamer_flutter_client'
  s.version          = '2.1.0-alpha.1'
  s.summary          = 'A Flutter plugin for Lightstreamer.'
  s.homepage         = 'https://github.com/Lightstreamer/lightstreamer_flutter_client'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lightstreamer' => 'support@lightstreamer.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.dependency 'LightstreamerClient', '~> 6.2.0'
end