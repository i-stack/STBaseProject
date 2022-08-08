#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'STBaseProject'
  s.version          = '1.0.4'
  s.summary          = 'Project infrastructure, common tools. The new project can inherit.'
#  s.description      = <<-DESC
#      Collect common classes in the development process. Can custom.
#                       DESC

  s.homepage         = 'https://github.com/i-stack/STBaseProject'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
#  s.author           = { 'songMW' => 'songshoubing7664@163.com' }
  s.source           = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_versions = ['5']
  
#  s.resources = ['STBaseProject/Assets/*']
#  s.public_header_files = 'Pod/Classes/**/*'

  s.default_subspecs = 'STBaseModule'
  s.subspec 'STBaseModule' do |ss|
    
    ss.source_files = [
        'STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseModel/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseView/*.swift'
    ]
    ss.dependency 'STBaseProject/STBaseConfig'
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

  s.subspec 'STHUD' do |ss|
      ss.source_files = ['STBaseProject/Classes/STHUD/*.swift']
      ss.dependency 'MBProgressHUD'
  end
  
end
