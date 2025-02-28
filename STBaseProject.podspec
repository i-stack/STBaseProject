#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.1.2'
  s.license = 'MIT'
  s.summary = 'Project infrastructure, common tools. The new project can inherit.'
  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version }
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5']

  s.subspec 'STConfig' do |ss|
    ss.source_files = ['STBaseProject/Classes/STConfig/*.swift']
  end
  
  s.subspec 'STBaseModule' do |ss|
    ss.subspec 'STBaseViewController' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift']
      sss.dependency 'STBaseProject/STBaseModule/STExtensionTools'
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

    ss.subspec 'STExtensionTools' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STExtensionTools/*.swift']
    end
    
    ss.dependency 'STBaseProject/STConfig'
  end
  
  s.subspec 'STDialog' do |ss|
    ss.source_files = ['STBaseProject/Classes/STDialog/*.swift']
    ss.dependency 'STBaseProject/STBaseModule/STExtensionTools'
  end
  
end
