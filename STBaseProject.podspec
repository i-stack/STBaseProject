#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'STBaseProject'
  s.version          = '0.1.0'
  s.summary          = 'Collect common classes in the development process.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
      Collect common classes in the development process. Can custom.
                       DESC

  s.homepage         = 'https://github.com/songMW/STBaseProject'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'songMW' => 'songshoubing7664@163.com' }
  s.source           = { :git => 'https://github.com/songMW/STBaseProject.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'STBaseProject/Classes/**/*'

  s.default_subspec = 'STBaseViewController'

  s.subspec 'STBaseViewController' do |ss|
    ss.source_files = [
      'STBaseProject/Classes/STBaseViewController/*',
      'STBaseProject/Classes/STCommonClass/*.STSwiftConstants.swift'
    ]
    ss.resource_bundles = {
      'STBaseProject' => ['STBaseProject/Assets/default_subspec/*.png']
    }
  end

#s.resource_bundles = {
#   'STBaseProject' => ['STBaseProject/Assets/*.png']
# }

#s.public_header_files = 'Pod/Classes/**/*'



  s.frameworks = 'UIKit', 'Twitter', 'MobileCoreServices', 'Security', 'QuartzCore', 'SystemConfiguration', 'JavaScriptCore', 'WebKit', 'CoreMedia', 'CoreTelephony', 'CoreLocation', 'CoreMotion', 'AdSupport', 'CFNetwork', 'MessageUI', 'AVFoundation', 'SafariServices', 'StoreKit', 'CoreGraphics'






  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
