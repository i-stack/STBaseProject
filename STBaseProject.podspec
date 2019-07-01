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

  s.resources = ['STBaseProject/Assets/*']
  
  s.default_subspecs = 'STBase'
  s.subspec 'STBase' do |ss|
    
    ss.subspec 'STBaseViewController' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBase/STBaseViewController/*.swift']
    end
    
    ss.subspec 'STBaseView' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBase/STBaseView/*.swift']
    end
    
    ss.subspec 'STBaseViewMode' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBase/STBaseViewMode/*.swift']
    end
    
    ss.subspec 'STBaseModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBase/STBaseModel/*.swift']
    end
    
    ss.subspec 'STBaseConstants' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBase/STBaseConstants/*.swift']
    end
  
  end

  s.subspec 'STCommon' do |ss|
    ss.source_files = 'STBaseProject/Classes/STCommon/*.swift'
  end
  
  s.subspec 'STExtension' do |ss|
    ss.source_files = 'STBaseProject/Classes/STExtension/*.swift'
  end
  
  s.subspec 'STUI' do |ss|

    ss.subspec 'STBtn' do |sss|
      sss.source_files = ['STBaseProject/Classes/STUI/STBtn/*.swift']
    end
    
    ss.subspec 'STScanner' do |sss|
      sss.source_files = ['STBaseProject/Classes/STUI/STScanner/*.swift']
    end
    
    ss.subspec 'STContract' do |sss|
      sss.source_files = ['STBaseProject/Classes/STUI/STContract/*.swift']
    end
    
    ss.subspec 'STScreenshot' do |sss|
      sss.source_files = ['STBaseProject/Classes/STUI/STScreenshot/*.swift']
    end
    
  end

  s.public_header_files = 'Pod/Classes/**/*'

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
