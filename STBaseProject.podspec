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
  s.summary = 'Modular iOS foundation library with MVVM base abstractions.'
  s.description = <<-DESC
    STBaseProject provides modular iOS foundation components built on MVVM base types.
    It includes reusable UI components and shared utilities for networking, localization, image handling, and security.
    Available via CocoaPods subspecs and Swift Package Manager.
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
    base.exclude_files = [
      'Sources/STContacts/**/*.swift',
      'Sources/STLocation/**/*.swift',
      'Sources/STMedia/**/*.swift',
      'Sources/STMarkdown/**/*.swift'
    ]
  end

  s.subspec 'STContacts' do |contacts|
    contacts.source_files = 'Sources/STContacts/*.swift'
  end

  s.subspec 'STLocation' do |location|
    location.source_files = 'Sources/STLocation/*.swift'
  end

  s.subspec 'STMedia' do |media|
    media.source_files = 'Sources/STMedia/*.swift'
  end

  # SPM parity (Package.swift): Markdown + SwiftMath modules via CocoaPods:
  # - swift-markdown-pod tracks github.com/GIKICoder/swift-markdown (≈ swift-markdown + swift-cmark GFM); not identical git pin as SPM `swiftlang/swift-markdown` branch main.
  # - SwiftMath-pod wraps github.com/GIKICoder/SwiftMath; SPM uses github.com/mgriebling/SwiftMath — bump both intentionally when you need matching upstreams.
  # swift-markdown-pod merges CAtomic into Markdown.framework; downstream Swift still needs the CAtomic modulemap flags below when compiling/importing Markdown.
  s.subspec 'STMarkdown' do |markdown|
    markdown.source_files = 'Sources/STMarkdown/**/*.swift'
    # STShimmerTextView lives in STUIKit and is referenced by STMarkdownStreamingTextView,
    # so the full core subspec is required as a transitive dep.
    markdown.dependency 'STBaseProject/STBaseProject'
    markdown.dependency 'swift-markdown-pod', '~> 1.0'
    # Pre-release tag from CocoaPods trunk; constraint required so `pod lib lint` / installs resolve.
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
