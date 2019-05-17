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

  s.resource_bundles = {
    #'STBaseProject' => ['STBaseProject/Assets/*.bundle']
  }
  
  s.resources = ['STBaseProject/Assets/*']
  
  s.default_subspecs = 'STBase'
  s.subspec 'STBase' do |ss|
    ss.source_files = ['STBaseProject/Classes/STBase/STBaseViewController/*.swift', 'STBaseProject/Classes/STBase/STUtils/*.swift']
  end

  s.subspec 'STContract' do |ss|
    ss.source_files = 'STBaseProject/Classes/STContract/*.swift'
  end

  s.subspec 'STScreenshot' do |ss|
    ss.source_files = 'STBaseProject/Classes/STScreenshot/*.swift'
  end

  s.subspec 'STScanner' do |scanner|
    scanner.source_files = 'STBaseProject/Classes/STScanner/*.swift'
    scanner.dependency 'STBaseProject/STBase'
  end

  s.public_header_files = 'Pod/Classes/**/*'

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
