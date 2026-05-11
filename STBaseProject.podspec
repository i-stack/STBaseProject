#
# Be sure to run `pod lib lint STBaseProject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'STBaseProject'
  s.version = '1.3.0'
  s.summary = 'Modular iOS foundation: MVVM bases, networking, security, UIKit, Markdown, localization (SPM & CocoaPods).'
  s.description = <<-DESC
    STBaseProject is an iOS 16+ modular foundation toolkit distributed via CocoaPods subspecs and Swift Package Manager.
    It includes STBaseViewController/STBaseViewModel patterns, STHTTPSession with interceptors and optional SSL pinning,
    Keychain and crypto helpers, UIKit components and dialogs, Markdown rendering (including tables and extensions),
    localization utilities, plus optional modules for Contacts, Location, and Media (camera/scan/screenshot).
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
  # 使用 :subspecs 时会覆盖本默认值；需要核心时请显式包含 'STBaseProject'，例如：
  # pod 'STBaseProject', '~> x.y.z', :subspecs => ['STBaseProject', 'STLocation']
  s.default_subspecs = ['STBaseProject']

  s.subspec 'STBaseProject' do |base|
    base.source_files = 'Sources/**/*.swift'
    base.exclude_files = [
      'Sources/STContacts/**/*.swift',
      'Sources/STLocation/**/*.swift',
      'Sources/STMedia/**/*.swift',
      'Sources/STMarkdown/**/*.swift'
    ]
    base.resource_bundles = {
      'STBaseProject_Privacy' => ['Sources/PrivacyInfo.xcprivacy']
    }
  end

  s.subspec 'STContacts' do |contacts|
    contacts.source_files = 'Sources/STContacts/*.swift'
    contacts.resource_bundles = {
      'STBaseProject_STContacts_Privacy' => ['Sources/STContacts/PrivacyInfo.xcprivacy']
    }
  end

  s.subspec 'STLocation' do |location|
    location.source_files = 'Sources/STLocation/*.swift'
    location.resource_bundles = {
      'STBaseProject_STLocation_Privacy' => ['Sources/STLocation/PrivacyInfo.xcprivacy']
    }
  end

  s.subspec 'STMedia' do |media|
    media.source_files = 'Sources/STMedia/*.swift'
    media.resource_bundles = {
      'STBaseProject_STMedia_Privacy' => ['Sources/STMedia/PrivacyInfo.xcprivacy']
    }
  end

  s.subspec 'STMarkdown' do |markdown|
    markdown.source_files = 'Sources/STMarkdown/**/*.swift'
    markdown.dependency 'STBaseProject/STBaseProject'
    markdown.dependency 'swift-markdown-pod', '~> 1.0'
    markdown.dependency 'SwiftMath-pod', '>= 2.0.1.pod'
    markdown.resource_bundles = {
      'STBaseProject_STMarkdown' => ['Sources/STMarkdown/Resources/*']
    }
    ca_atomic = '$(inherited) -Xcc -fmodule-map-file="$(PODS_ROOT)/swift-markdown-pod/Sources/CAtomic/include/module.modulemap" -Xcc -I"$(PODS_ROOT)/swift-markdown-pod/Sources/CAtomic/include"'
    markdown.pod_target_xcconfig = {
      'OTHER_SWIFT_FLAGS' => ca_atomic
    }
    markdown.user_target_xcconfig = {
      'OTHER_SWIFT_FLAGS' => ca_atomic
    }
  end

end
