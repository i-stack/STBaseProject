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

    # 模块化设计 - 核心模块
    s.subspec 'STBaseModule' do |base|
        base.source_files = [
            'STBaseProject/Classes/STBaseModule/**/*.swift', 
            'STBaseProject/Classes/STConfig/**/*.swift'
        ]
    end

    # STKit 工具集模块
    s.subspec 'STKit' do |kit|
        kit.subspec 'Core' do |core|
            core.source_files = 'STBaseProject/Classes/STKit/Core/**/*.swift'
            core.dependency 'STBaseProject/STBaseModule'
        end

        kit.subspec 'UI' do |ui|
            ui.source_files = 'STBaseProject/Classes/STKit/UI/**/*.swift'
            ui.dependency 'STBaseProject/STBaseModule'
            ui.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Network' do |network|
            network.source_files = 'STBaseProject/Classes/STKit/Network/**/*.swift'
            network.dependency 'STBaseProject/STBaseModule'
            network.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Media' do |media|
            media.source_files = 'STBaseProject/Classes/STKit/Media/**/*.swift'
            media.dependency 'STBaseProject/STBaseModule'
            media.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Scan' do |scan|
            scan.source_files = 'STBaseProject/Classes/STKit/Scan/**/*.swift'
            scan.dependency 'STBaseProject/STBaseModule'
            scan.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Security' do |security|
            security.source_files = 'STBaseProject/Classes/STKit/Security/**/*.swift'
            security.dependency 'STBaseProject/STBaseModule'
            security.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Localization' do |localization|
            localization.source_files = 'STBaseProject/Classes/STKit/Localization/**/*.swift'
            localization.dependency 'STBaseProject/STBaseModule'
            localization.dependency 'STBaseProject/STKit/Core'
        end

        kit.subspec 'Location' do |location|
            location.source_files = 'STBaseProject/Classes/STKit/Location/**/*.swift'
            location.dependency 'STBaseProject/STBaseModule'
            location.dependency 'STBaseProject/STKit/Core'
        end
    end

    s.default_subspecs = ['STBaseModule', 'STKit']

end