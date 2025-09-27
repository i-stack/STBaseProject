#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name = 'STBaseProject'
    s.version = '1.1.5'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.summary = 'A powerful iOS base project with modular architecture and rich UI components.'
    s.description = <<-DESC
        STBaseProject is a comprehensive iOS development framework that provides:
        - Modular architecture with independent STBase modules
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
    
    s.subspec 'STBase' do |base|
        base.source_files = 'Sources/**/*.swift'
    end
    
    s.default_subspecs = ['STBase']

end