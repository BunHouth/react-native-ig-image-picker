require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-ig-image-picker"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = "Instagram-like image picker & filters for iOS supporting videos and albums"
  s.homepage     = "https://github.com/BunHouth/react-native-ig-image-picker"
  s.license      = "MIT"
  s.authors      = { "Bun" => "bunhouth99@gmail.com" }
  s.platforms    = { :ios => "9.0" }
  s.source       = { :git => "https://github.com/BunHouth/react-native-ig-image-picker.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency "YPImagePicker"
end
