Pod::Spec.new do |s|
  s.name             = 'CurlDSL'
  s.version          = '0.0.2'
  s.summary          = 'CurlDSL converts cURL commands into `URLRequest` objects.'
  s.description      = <<-DESC
CurlDSL converts cURL commands into `URLRequest` objects. The Swift package
helps you to build HTTP clients in your iOS/macOS/tvOS easier, once you have a
cURL command example for a Web API endpoint.
                       DESC

  s.homepage         = 'https://github.com/zonble/CurlDSL'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zonble' => 'zonble@gmail.com' }
  s.source           = { :git => 'https://github.com/zonble/CurlDSL.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/zonble'
  s.swift_versions   = [5.0, 5.1]

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.source_files = 'Sources/CurlDSL/**/*'
end
