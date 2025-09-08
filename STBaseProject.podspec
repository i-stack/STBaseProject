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
  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.stbaseproject.framework',
    'CODE_SIGNING_ALLOWED' => 'NO',
    'CODE_SIGNING_REQUIRED' => 'NO'
  }
  
  # 确保 Info.plist 被正确生成
  s.info_plist = {
    'CFBundlePackageType' => 'FMWK',
    'CFBundleShortVersionString' => s.version.to_s,
    'CFBundleVersion' => '1',
    'CFBundleName' => s.name
  }
  
  s.documentation_url = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'
  s.readme = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'

  # 默认引入（快速开始推荐配置）
  s.default_subspecs = ['STConfig', 'STKit/Core', 'STKit/UI', 'STKit/Network', 'STKit/Localization', 'STBaseModule']

  # 核心配置
  s.subspec 'STConfig' do |ss|
    ss.source_files = ['STBaseProject/Classes/STConfig/*.swift']
  end

  # STKit 模块化工具集 - 优化后的依赖结构
  s.subspec 'STKit' do |kit|
    
    # 基础核心模块 - 无依赖，包含共享类型和基础工具
    kit.subspec 'Core' do |core|
      core.source_files = ['STBaseProject/Classes/STKit/Core/*.swift']
      core.dependency 'STBaseProject/STConfig'
    end
    
    # 本地化模块 - 只依赖 Core
    kit.subspec 'Localization' do |loc|
      loc.source_files = ['STBaseProject/Classes/STKit/Localization/*.swift']
      loc.dependency 'STBaseProject/STKit/Core'
    end

    # 安全模块 - 只依赖 Core，移除对 Network 的依赖
    kit.subspec 'Security' do |sec|
      sec.source_files = ['STBaseProject/Classes/STKit/Security/*.swift']
      sec.dependency 'STBaseProject/STKit/Core'
    end

    # 网络模块 - 只依赖 Core，移除对 Security 的依赖
    kit.subspec 'Network' do |net|
      net.source_files = ['STBaseProject/Classes/STKit/Network/*.swift']
      net.dependency 'STBaseProject/STKit/Core'
    end
    
    # UI 组件 - 依赖 Core 和 Localization
    kit.subspec 'UI' do |ui|
      ui.source_files = ['STBaseProject/Classes/STKit/UI/*.swift']
      ui.dependency 'STBaseProject/STKit/Core'
      ui.dependency 'STBaseProject/STKit/Localization'
    end
    
    # 媒体处理 - 依赖 Core 和 Localization
    kit.subspec 'Media' do |media|
      media.source_files = ['STBaseProject/Classes/STKit/Media/*.swift']
      media.dependency 'STBaseProject/STKit/Core'
      media.dependency 'STBaseProject/STKit/Localization'
    end

    # 位置服务 - 只依赖 Core
    kit.subspec 'Location' do |location|
      location.source_files = ['STBaseProject/Classes/STKit/Location/*.swift']
      location.dependency 'STBaseProject/STKit/Core'
    end

    # 扫描功能 - 依赖 Core 和 Media
    kit.subspec 'Scan' do |scan|
      scan.source_files = ['STBaseProject/Classes/STKit/Scan/*.swift']
      scan.dependency 'STBaseProject/STKit/Core'
      scan.dependency 'STBaseProject/STKit/Media'
    end

    # 对话框组件 - 依赖 Core 和 UI
    kit.subspec 'Dialog' do |dialog|
      dialog.source_files = ['STBaseProject/Classes/STKit/STDialog/*.swift']
      dialog.dependency 'STBaseProject/STKit/Core'
      dialog.dependency 'STBaseProject/STKit/UI'
    end
  end

  # Complete MVVM architecture base classes - 优化后的依赖结构
  s.subspec 'STBaseModule' do |ss|
    
    # Base model - 无依赖，最基础的数据模型
    ss.subspec 'STBaseModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseModel/*.swift']
    end

    # Base view - 无依赖，最基础的视图组件
    ss.subspec 'STBaseView' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseView/*.swift']
    end

    # Base view model - 依赖 Core 和 Network
    ss.subspec 'STBaseViewModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift']
      sss.dependency 'STBaseProject/STKit/Core'
      sss.dependency 'STBaseProject/STKit/Network'
    end

    # Base view controller - 依赖 UI
    ss.subspec 'STBaseViewController' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift']
      sss.dependency 'STBaseProject/STKit/UI'
    end
    
    # STBaseModule 整体依赖 STConfig
    ss.dependency 'STBaseProject/STConfig'
  end

end
