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
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.stbaseproject.framework'
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

  # STKit 模块化工具集
  s.subspec 'STKit' do |kit|
    
    # Essential utilities: data processing, strings, colors, device info
    kit.subspec 'Core' do |core|
      core.source_files = ['STBaseProject/Classes/STKit/Core/*.swift']
      core.dependency 'STBaseProject/STConfig'
    end
    
    # UI components: buttons, labels, alerts, font manager
    kit.subspec 'UI' do |ui|
      ui.source_files = ['STBaseProject/Classes/STKit/UI/*.swift']
      ui.dependency 'STBaseProject/STKit/Core'
      ui.dependency 'STBaseProject/STKit/Localization'
    end

    # Network utilities: HTTP session, monitoring
    kit.subspec 'Network' do |net|
      net.source_files = ['STBaseProject/Classes/STKit/Network/*.swift']
      net.dependency 'STBaseProject/STKit/Core'
      net.dependency 'STBaseProject/STKit/Security'
    end

    # Internationalization support and language management
    kit.subspec 'Localization' do |loc|
      loc.source_files = ['STBaseProject/Classes/STKit/Localization/*.swift']
      loc.dependency 'STBaseProject/STKit/Core'
    end

    # Security tools: encryption, keychain helper
    kit.subspec 'Security' do |sec|
      sec.source_files = ['STBaseProject/Classes/STKit/Security/*.swift']
      sec.dependency 'STBaseProject/STKit/Core'
    end
    
    # Image processing, compression, and screenshot utilities
    kit.subspec 'Media' do |media|
      media.source_files = ['STBaseProject/Classes/STKit/Media/*.swift']
      media.dependency 'STBaseProject/STKit/Core'
      media.dependency 'STBaseProject/STKit/Localization'
    end

    # QR/Barcode scanning with customizable UI
    kit.subspec 'Scan' do |scan|
      scan.source_files = ['STBaseProject/Classes/STKit/Scan/*.swift']
      scan.dependency 'STBaseProject/STKit/Core'
      scan.dependency 'STBaseProject/STKit/Media'
    end

    # Location services and management
    kit.subspec 'Location' do |location|
      location.source_files = ['STBaseProject/Classes/STKit/Location/*.swift']
      location.dependency 'STBaseProject/STKit/Core'
    end

    # Progress HUD and dialog components
    kit.subspec 'Dialog' do |dialog|
      dialog.source_files = ['STBaseProject/Classes/STKit/STDialog/*.swift']
      dialog.dependency 'STBaseProject/STKit/Core'
      dialog.dependency 'STBaseProject/STKit/UI'
    end
  end

  # Complete MVVM architecture base classes
  s.subspec 'STBaseModule' do |ss|
    
    # Base view controller with navigation bar customization
    ss.subspec 'STBaseViewController' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewController/*.swift']
      sss.dependency 'STBaseProject/STKit/UI'
    end

    # Base view with multiple layout modes and auto-scroll detection
    ss.subspec 'STBaseView' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseView/*.swift']
    end

    # Base view model with network requests, caching, and state management
    ss.subspec 'STBaseViewModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseViewModel/*.swift']
      sss.dependency 'STBaseProject/STKit/Core'
      sss.dependency 'STBaseProject/STKit/Network'
    end

    # Base model with standard and flexible modes, dictionary conversion
    ss.subspec 'STBaseModel' do |sss|
      sss.source_files = ['STBaseProject/Classes/STBaseModule/STBaseModel/*.swift']
    end
    
    ss.dependency 'STBaseProject/STConfig'
  end

end
