#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.0.7'
  s.license = 'MIT'
  s.summary = 'Project infrastructure, common tools. The new project can inherit.'
  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5']
  
  s.default_subspecs = 'STBaseModule'
  s.subspec 'STBaseModule' do |ss|
    ss.source_files = [
        'STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseModel/*.swift',
        'STBaseProject/Classes/STBaseModule/STBaseView/*.swift'
    ]
    ss.dependency 'STBaseProject/STCustomTools'
  end
  
  s.subspec 'STBaseConfig' do |ss|
    ss.source_files = ['STBaseProject/Classes/STBaseConfig/*.swift']
  end
  
  s.subspec 'STCustomTools' do |ss|
    ss.source_files = ['STBaseProject/Classes/STCustomTools/*.swift']
    ss.dependency 'STBaseProject/STBaseConfig'
  end
  
#  s.subspec 'STOptionalTools' do |ss|
#    ss.source_files = ['STBaseProject/Classes/STOptionalTools/*.swift']
#  end
    
  s.subspec 'STScanner' do |ss|
    ss.source_files = ['STBaseProject/Classes/STOptionalTools/STScanner/*.swift']
  end

  s.subspec 'STScreenshot' do |ss|
    ss.source_files = ['STBaseProject/Classes/STOptionalTools/STScreenshot/*.swift']
  end

  s.subspec 'STHUD' do |ss|
    ss.source_files = ['STBaseProject/Classes/STOptionalTools/STHUD/*.swift']
  end
  
end
