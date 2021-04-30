# Uncomment the next line to define a global platform for your project

target 'Romo' do
  platform :ios, '7.0'
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for Romo
  pod 'Romo'#, :path => '../Romo-iOS-SDK'
  pod 'Romo/RMCharacter'#, :path => '../Romo-iOS-SDK'
  pod 'Romo/RMVision'#, :path => '../Romo-iOS-SDK'
  pod 'CocoaLumberjack'
  pod 'AFNetworking', '~> 3.0'
  pod 'FFmpeg-static', :git => 'https://github.com/stephanecopin/FFmpeg-static.git'
end

target 'Romo Control' do
  platform :ios, '8.0'
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for Romo Control
  pod 'Romo/RMCharacter'#, :path => '../Romo-iOS-SDK'
  pod 'CocoaLumberjack'
  pod 'SocketRocket', :git => 'https://github.com/Gkpsundar/SocketRocket.git'
end

# Mac Catalyst workaround
post_install do |installer|
    installer.pods_project.targets.each do |target|
        # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
        if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
            target.build_configurations.each do |config|
                config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
            end
        end
    end
end
