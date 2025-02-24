#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.1.3'
  s.license = 'MIT'
  s.summary = 'Project infrastructure, common tools. The new project can inherit.'
  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5']
  
#  s.default_subspecs = 'STBaseModule'
  s.subspec 'STBaseModule' do |ss|
    ss.source_files = [
      'STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift',
      'STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift',
      'STBaseProject/Classes/STBaseModule/STBaseModel/*.swift',
      'STBaseProject/Classes/STBaseModule/STBaseView/*.swift',
      'STBaseProject/Classes/STBaseModule/STBaseConfig/*.swift',
    ]
    ss.dependency 'STBaseProject/STDeviceInfo'
    ss.dependency 'STBaseProject/STExtension'
    ss.dependency 'STBaseProject/STUIControl'
    ss.dependency 'STBaseProject/STThread'
    ss.dependency 'STBaseProject/STHTTP'
  end
  
  s.subspec 'STDeviceInfo' do |ss|
    ss.source_files = ['STBaseProject/Classes/STDeviceInfo/*.swift']
    ss.dependency 'DeviceKit'
  end

  s.subspec 'STExtension' do |ss|
    ss.source_files = ['STBaseProject/Classes/STExtension/*.swift']
  end
  
  s.subspec 'STUIControl' do |ss|
    ss.source_files = ['STBaseProject/Classes/STUIControl/*.swift']
    ss.dependency 'STBaseProject/STManager'
  end
    
  s.subspec 'STManager' do |ss|
    ss.source_files = ['STBaseProject/Classes/STManager/*.swift']
  end
  
  s.subspec 'STThread' do |ss|
    ss.source_files = ['STBaseProject/Classes/STThread/*.swift']
  end
  
  s.subspec 'STHTTP' do |ss|
    ss.source_files = ['STBaseProject/Classes/STHTTP/*.swift']
  end

  s.subspec 'STDialog' do |ss|
    ss.source_files = ['STBaseProject/Classes/STDialog/*.swift']
    ss.dependency 'MBProgressHUD'
  end
  
  s.subspec 'STOther' do |ss|
    ss.source_files = ['STBaseProject/Classes/STOther/*.swift']
  end
  
end
