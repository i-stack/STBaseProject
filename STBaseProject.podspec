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
        - Modular STBaseModule with Core/UI/Security/Config modules
        - Complete MVVM architecture with STBaseViewController, STBaseViewModel, STBaseModel, STBaseView
        - Rich UI components including custom buttons, labels, alerts, and scan views
        - Unified image management, network session, localization, and security tools
        - Easy integration with CocoaPods and SPM, supports selective module importing
    DESC
    
    s.homepage = 'https://github.com/i-stack/STBaseProject'
    s.author = { 'i-stack' => 'songshoubing7664@163.com' }
    s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '13.0'
    s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9']
    
    s.requires_arc = true

    s.documentation_url = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'
    s.readme = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'

    # ==================== 基础架构模块 ====================
    
    # STBaseModule - 基础架构模块（包含 Core、UI、Security、Config）
    s.subspec 'STBaseModule' do |base|
        base.source_files = 'Sources/STBaseModule/**/*.swift'
    end

    # ==================== STKit 专业功能模块 ====================

    # STKitLocation - 位置服务模块
    s.subspec 'STKitLocation' do |location|
        location.source_files = 'Sources/STKitLocation/**/*.swift'
        location.dependency 'STBaseProject/STBaseModule'
    end

    # STKitScan - 扫描功能模块
    s.subspec 'STKitScan' do |scan|
        scan.source_files = 'Sources/STKitScan/**/*.swift'
        scan.dependency 'STBaseProject/STBaseModule'
    end

    # STKitMedia - 媒体处理模块
    s.subspec 'STKitMedia' do |media|
        media.source_files = 'Sources/STKitMedia/**/*.swift'
        media.dependency 'STBaseProject/STBaseModule'
        media.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/STBaseModule' }
    end

    # STKitDialog - 对话框组件模块
    s.subspec 'STKitDialog' do |dialog|
        dialog.source_files = 'Sources/STKitDialog/**/*.swift'
        dialog.dependency 'STBaseProject/STBaseModule'
        dialog.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/STBaseModule' }
    end

    # ==================== 默认配置 ====================
    
    # 默认包含基础架构模块
    s.default_subspecs = ['STBaseModule']

end