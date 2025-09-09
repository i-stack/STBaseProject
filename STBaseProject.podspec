#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name = 'STBaseProject'
    s.version = '1.1.4'
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
    
    # STBaseProject - 基础架构模块（包含 Core、UI、Security、Config）
    s.subspec 'STBaseProject' do |base|
        base.source_files = 'Sources/STBaseProject/**/*.swift'
    end

    # ==================== ST 专业功能模块 ====================

    # STLocation - 位置服务模块
    s.subspec 'STLocation' do |location|
        location.source_files = 'Sources/STLocation/**/*.swift'
        location.dependency 'STBaseProject/STBaseProject'
    end

    # STScan - 扫描功能模块
    s.subspec 'STScan' do |scan|
        scan.source_files = 'Sources/STScan/**/*.swift'
        scan.dependency 'STBaseProject/STBaseProject'
    end

    # STMedia - 媒体处理模块
    s.subspec 'STMedia' do |media|
        media.source_files = 'Sources/STMedia/**/*.swift'
        media.dependency 'STBaseProject/STBaseProject'
        media.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/STBaseProject' }
    end

    # STDialog - 对话框组件模块
    s.subspec 'STDialog' do |dialog|
        dialog.source_files = 'Sources/STDialog/**/*.swift'
        dialog.dependency 'STBaseProject/STBaseProject'
        dialog.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/STBaseProject' }
    end

    # ==================== 默认配置 ====================
    
    # 默认包含基础架构模块
    s.default_subspecs = ['STBaseProject']

end