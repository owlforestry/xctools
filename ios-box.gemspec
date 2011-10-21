# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ios-box', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{Include atuomatic vesion conrol for you XCode projects.}
  gem.summary       = %q{Add handy tools to XCode specially for iOS development}
  gem.homepage      = "https://github.com/owl-forestry/ios-box"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "ios-box"
  gem.require_paths = ["lib"]
  gem.version       = IOSBox::VERSION
  
  gem.add_runtime_dependency  "thor"
  gem.add_runtime_dependency  "grit"
  gem.add_runtime_dependency  "plist"
  gem.add_runtime_dependency  "rubyzip"
  gem.add_runtime_dependency  "rest-client"
end
