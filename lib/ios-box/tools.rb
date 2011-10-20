require 'ios-box/iosbox'
require 'thor'

module Ios
  module Box
    module Tools
      autoload :Version, 'ios-box/tools/version'
      autoload :Build, 'ios-box/tools/build'
      autoload :Config, 'ios-box/tools/config'
      autoload :Deploy, 'ios-box/tools/deploy'
    end
  end
end
