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

    s.documentation_url = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'
    s.readme = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'

    # ==================== 默认模块 ====================
    
    # STBaseModule - 基础模块
    s.subspec 'STBaseModule' do |base|
        base.source_files = 'STBaseProject/Classes/STBaseModule/**/*.swift'
    end

    # STConfig - 配置模块
    s.subspec 'STConfig' do |config|
        config.source_files = 'STBaseProject/Classes/STConfig/**/*.swift'
    end

    # STKit/Core - 核心工具模块
    s.subspec 'STKit' do |kit|
        kit.subspec 'Core' do |core|
            core.source_files = 'STBaseProject/Classes/STKit/Core/**/*.swift'
            core.dependency 'STBaseProject/STConfig'
        end

        # STKit/UI - UI组件模块
        kit.subspec 'UI' do |ui|
            ui.source_files = 'STBaseProject/Classes/STKit/UI/**/*.swift'
            ui.dependency 'STBaseProject/STBaseModule'
            ui.dependency 'STBaseProject/STKit/Core'
        end

        # STKit/Network - 网络模块
        kit.subspec 'Network' do |network|
            network.source_files = 'STBaseProject/Classes/STKit/Network/**/*.swift'
            network.dependency 'STBaseProject/STBaseModule'
            network.dependency 'STBaseProject/STKit/Core'
        end

        # STKit/Security - 安全模块
        kit.subspec 'Security' do |security|
            security.source_files = 'STBaseProject/Classes/STKit/Security/**/*.swift'
            security.dependency 'STBaseProject/STBaseModule'
            security.dependency 'STBaseProject/STKit/Core'
        end

        # STKit/Localization - 本地化模块
        kit.subspec 'Localization' do |localization|
            localization.source_files = 'STBaseProject/Classes/STKit/Localization/**/*.swift'
            localization.dependency 'STBaseProject/STBaseModule'
            localization.dependency 'STBaseProject/STKit/Core'
        end

        # ==================== 可选模块 ====================

        # STKit/Location - 位置模块（可选）
        kit.subspec 'Location' do |location|
            location.source_files = 'STBaseProject/Classes/STKit/Location/**/*.swift'
            location.dependency 'STBaseProject/STBaseModule'
            location.dependency 'STBaseProject/STKit/Core'
        end

        # STKit/Scan - 扫描模块（可选）
        kit.subspec 'Scan' do |scan|
            scan.source_files = 'STBaseProject/Classes/STKit/Scan/**/*.swift'
            scan.dependency 'STBaseProject/STBaseModule'
            scan.dependency 'STBaseProject/STKit/Core'
        end

        # STKit/Media - 媒体模块（可选）
        kit.subspec 'Media' do |media|
            media.source_files = 'STBaseProject/Classes/STKit/Media/**/*.swift'
            media.dependency 'STBaseProject/STBaseModule'
            media.dependency 'STBaseProject/STKit/Core'
        end
    end

    # 默认只包含默认模块，不包含可选模块
    s.default_subspecs = ['STBaseModule', 'STConfig', 'STKit/Core', 'STKit/UI', 'STKit/Network', 'STKit/Security', 'STKit/Localization']

end