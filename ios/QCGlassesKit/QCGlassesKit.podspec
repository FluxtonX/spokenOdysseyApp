# Local pod that bundles the vendor QC glasses SDK (QCSDK) for the Runner app.
#
# QCSDK is shipped for real iPhones only (arm64 device slice). The Podfile
# post_install hook links these frameworks for `iphoneos` builds only, and the
# Swift sources compile the SDK calls only on device, so Simulator builds still
# work (glasses features report "unsupported" there).
Pod::Spec.new do |s|
  s.name             = 'QCGlassesKit'
  s.version          = '1.0.0'
  s.summary          = 'Spoken Odyssey bridge to the QC smart glasses SDK.'
  s.homepage         = 'https://spokenodyssey.app'
  s.license          = { :type => 'Proprietary', :text => 'Proprietary' }
  s.author           = 'Spoken Odyssey'
  s.source           = { :path => '.' }
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.source_files        = 'Classes/**/*.swift'
  s.vendored_frameworks = 'Frameworks/QCSDK.framework', 'Frameworks/JLAudioUnitKit.framework'
  s.frameworks          = 'CoreBluetooth', 'CoreImage', 'NetworkExtension', 'Network',
                          'SystemConfiguration', 'AVFoundation', 'AudioToolbox', 'UIKit'
end
