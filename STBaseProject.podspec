#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.1.3.0'
  s.license = 'MIT'
  s.summary = 'Project infrastructure, common tools. The new project can inherit.'
  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5']
  
#  s.default_subspecs = 'STBaseModule'
  s.subspec 'STBaseModule' do |ss|
    ss.source_files = ['STBaseProject/Classes/STConfig/*.swift'
#      'STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift',
#      'STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift',
#      'STBaseProject/Classes/STBaseModule/STBaseModel/*.swift',
#      'STBaseProject/Classes/STBaseModule/STBaseView/*.swift',
    ]
    
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
    
#    ss.subspec 'STConfig' do |sss|
#      sss.source_files = ['STBaseProject/Classes/STConfig/*.swift']
#    end

    ss.subspec 'STExtension' do |sss|
      sss.source_files = ['STBaseProject/Classes/STExtension/*.swift']
    end
    
#    ss.dependency 'STBaseProject/STConfig'
#    ss.dependency 'STBaseProject/STExtension'
  end
  
#  s.subspec 'STBaseConfig' do |ss|
#    ss.source_files = ['STBaseProject/Classes/STConfig/*.swift']
#  end
#
#  s.subspec 'STExtension' do |ss|
#    ss.source_files = ['STBaseProject/Classes/STExtension/*.swift']
#  end
  
#  s.subspec 'STUIControl' do |ss|
#    ss.source_files = ['STBaseProject/Classes/STUIControl/*.swift']
#    ss.dependency 'STBaseProject/STExtension'
#  end

#  s.subspec 'STDialog' do |ss|
#    ss.source_files = ['STBaseProject/Classes/STDialog/*.swift']
#    ss.dependency 'MBProgressHUD'
#    ss.dependency 'STBaseProject/STUIControl'
#  end
  
  s.subspec 'STOther' do |ss|
    ss.source_files = ['STBaseProject/Classes/STOther/*.swift']
  end
  
end
