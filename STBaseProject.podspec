#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '2.0.0'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'A powerful iOS base project with modular architecture and rich UI components.'
  s.description = <<-DESC
    STBaseProject is a comprehensive iOS development framework that provides:
    - Modular STKit toolset with Core/UI/Network/Media/Scan/Security/Localization/Location modules
    - Complete MVVM architecture with STBaseViewController, STBaseViewModel, STBaseModel, STBaseView
    - Rich UI components including custom buttons, labels, alerts, and scan views
    - Unified image management, network session, localization, and security tools
    - Easy integration with CocoaPods, supports selective module importing
  DESC
  
  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9']
  
  s.requires_arc = true
  
  # 优化的配置，避免沙盒权限问题
  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'SWIFT_VERSION' => '5.0',
    'CODE_SIGNING_ALLOWED' => 'NO',
    'CODE_SIGNING_REQUIRED' => 'NO',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.stbaseproject.framework'
  }

  s.documentation_url = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'
  s.readme = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'

  # 将所有模块作为核心引入，去除模块化设计
  s.source_files = [
    'STBaseProject/Classes/**/*.swift'
  ]
  
  # 移除所有子模块依赖，将所有内容作为单一模块
  # 不定义任何依赖，所有内容作为单一模块

end
