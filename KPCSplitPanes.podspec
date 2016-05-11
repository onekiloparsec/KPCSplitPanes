Pod::Spec.new do |s|
  s.name         = "KPCSplitPanes"
  s.version      = "0.1.0"
  s.summary      = "A view controller that splits well, according to some user-limits, well suited to make split panes."
  s.homepage     = "https://github.com/onekiloparsec/KPCJumpBarControl.git"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Cédric Foellmi" => "cedric@onekilopars.ec" }
  s.source       = { :git => "https://github.com/onekiloparsec/KPCSplitPanes.git", :tag => "#{s.version}" }
  s.source_files = 'KPCSplitPanes/*.{swift,}'
  s.platform     = :osx, '10.10'
  s.framework    = 'QuartzCore', 'AppKit'
  s.requires_arc = true
  s.resources    = 'Resources/*.pdf'
end
