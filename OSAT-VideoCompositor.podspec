#
# Be sure to run `pod lib lint OSAT-VideoCompositor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OSAT-VideoCompositor'
  s.version          = '0.1.0'
  s.summary          = 'Allow iOS app developers to annotate and augment a video file using Apple native Video composition APIs.'
  s.swift_version    = '5.5'

# This description is used to generate tags and improve search results.


  s.description      = <<-DESC
OSAT-VideoCompositor is an open source project which allow iOS app developers to annotate and augment a video file using Apple native Video composition APIs
                       DESC

  s.homepage         = 'https://github.com/OSAT-OpenSourceAppleTech/OSAT-VideoCompositor.git'
  s.license          = { :type => 'GNU GENERAL PUBLIC LICENSE', :file => 'LICENSE' }
  s.author           = { 'Hem Dutt' => 'hemdutt.developer@gmail.com' }
  s.source           = { :git => 'https://github.com/OSAT-OpenSourceAppleTech/OSAT-VideoCompositor.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.linkedin.com/in/hem-dutt-65a16630/'

  s.ios.deployment_target = '15.0'

  s.source_files = 'OSAT-VideoCompositor/Classes/**/*'
  s.test_spec 'UnitTests' do |test_spec|
  test_spec.source_files = 'OSAT-VideoCompositor/UnitTests/**/*'
  end
  
  # s.resource_bundles = {
  #   'OSAT-VideoCompositor' => ['OSAT-VideoCompositor/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
