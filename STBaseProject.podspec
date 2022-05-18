#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'STBaseProject'
  s.version          = '1.0.2'
#  s.summary          = 'Collect common classes in the development process.'
#  s.description      = <<-DESC
#      Collect common classes in the development process. Can custom.
#                       DESC

  s.homepage         = 'https://github.com/i-stack/STBaseProject'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'songMW' => 'songshoubing7664@163.com' }
  s.source           = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_versions = ['5']
  
#  s.resources = ['STBaseProject/Assets/*']
#  s.public_header_files = 'Pod/Classes/**/*'

  s.default_subspecs = 'STBaseModule'
  s.subspec 'STBaseModule' do |ss|
    
    ss.subspec 'STBaseViewController' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift']
    end

    ss.subspec 'STBaseView' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseView/*.swift']
    end
    
    ss.subspec 'STBaseViewModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift']
    end
    
    ss.subspec 'STBaseModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseModel/*.swift']
    end
    
  end
  
  s.subspec 'STBaseConfig' do |ss|
      ss.source_files = ['STBaseProject/Classes/STBaseConfig/*.swift']
  end
    
  s.subspec 'STScanner' do |ss|
      ss.source_files = ['STBaseProject/Classes/STScanner/*.swift']
  end

  s.subspec 'STScreenshot' do |ss|
      ss.source_files = ['STBaseProject/Classes/STScreenshot/*.swift']
  end

  #  s.subspec 'STHUD' do |ss|
  #      ss.source_files = ['STBaseProject/Classes/STHUD/*.swift']
  #      ss.dependency 'MBProgressHUD'
  #  end
  
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
