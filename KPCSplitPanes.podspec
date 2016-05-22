Pod::Spec.new do |s|
  s.name         = "KPCSplitPanes"
  s.version      = "0.3.0"
  s.summary      = "A set of classes, among which a subclass of NSSplitView, that splits when you're intented to make panes."
  s.homepage     = "https://github.com/onekiloparsec/KPCJumpBarControl.git"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Cédric Foellmi" => "cedric@onekilopars.ec" }
  s.source       = { :git => "https://github.com/onekiloparsec/KPCSplitPanes.git", :tag => "#{s.version}" }
  s.source_files = 'KPCSplitPanes/*.{swift,}'
  s.platform     = :osx, '10.11'
  s.framework    = 'QuartzCore', 'AppKit'
  s.requires_arc = true
  s.resources    = 'Resources/*.png'
end
