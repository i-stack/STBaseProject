#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.6.0'
  s.summary = 'Modular iOS foundation: MVVM bases, networking, security, UIKit, localization (SPM & CocoaPods).'
  s.description = <<-DESC
    STBaseProject is an iOS 16+ modular foundation toolkit distributed via Swift Package Manager and CocoaPods.
    It includes STBaseViewController/STBaseViewModel patterns, STHTTPSession with interceptors and optional SSL pinning,
    Keychain and crypto helpers, UIKit components and dialogs, localization utilities.
    Modules requiring permissions (Contacts, Location, Media, Markdown) have been split into standalone repositories:
    STContacts, STLocation, STMedia, STMarkdown.
  DESC

  s.homepage = 'https://github.com/i-stack/STBaseProject'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'i-stack' => 'songshoubing7664@163.com' }
  s.source = { :git => 'https://github.com/i-stack/STBaseProject.git', :tag => s.version.to_s }
  s.documentation_url = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'
  s.readme = 'https://github.com/i-stack/STBaseProject/blob/main/README.md'

  s.ios.deployment_target = '16.0'
  s.swift_versions = %w[5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 5.10 5.11]
  s.requires_arc = true
  
  s.default_subspecs = ['STBaseProject']

  s.subspec 'STBaseProject' do |base|
    base.source_files = 'Sources/**/*.swift'
    base.resource_bundles = {
      'STBaseProject_Privacy' => ['Sources/PrivacyInfo.xcprivacy']
    }
  end

end
