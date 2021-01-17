# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Romo X' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for Romo X
  pod 'Romo'#, :path => '../Romo'
  pod 'Romo/RMCharacter'#, :path => '../Romo'
  pod 'Romo/RMVision'#, :path => '../Romo'
  pod 'CocoaLumberjack'
  pod 'AFNetworking', '~> 4.0'
  pod 'UICKeyChainStore'
end

target 'Romo X Control' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for Romo X Control
  pod 'Romo/RMCharacter'#, :path => '../Romo'
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
