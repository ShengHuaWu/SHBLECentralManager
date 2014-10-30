
Pod::Spec.new do |s|

  s.name         = "SHBLECentralManager"
  s.version      = "0.0.1"
  s.summary      = "A BLE connection manager."
  s.description  = "This project wraps a central manager of the Core BlueTooth framework."
  s.homepage     = "https://github.com/ShengHuaWu/SHBLECentralManager"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ShengHua Wu" => "fantasy0404@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/ShengHuaWu/SHBLECentralManager.git", :tag => "#{s.version}" }
  s.source_files = "SHBLECentralManager/Classes/SHBLECentralManager.{h,m}"
  s.frameworks   = "CoreBluetooth"
  s.requires_arc = true

end
