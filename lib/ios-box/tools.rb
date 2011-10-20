require 'ios-box/iosbox'
require 'thor'

module Ios
  module Box
    module Tools
      autoload :Version, 'ios-box/tools/version'
      
      class Tool
        attr_reader :shell, :options
        
        def initialize(options = {})
          @shell = Thor::Shell::Color.new
          
          @iosbox = IOSBox.new
          
          @options = options
        end
      end
    end
  end
end
