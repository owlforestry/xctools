require 'ios-box/config'
require 'ios-box/iosbox'

require 'rake/tasklib'
require 'rubygems'
require 'yaml'
require 'grit'
require 'plist'
require 'pbxproject'

module Ios
  module Box
    class Tasks < ::Rake::TaskLib
      def initialize(namespace = :iosbox, &block)
      end
      
    private
      def require_xcode
        raise "This task must be run in XCode Environment" unless ENV['XCODE_VERSION_ACTUAL']
      end
    end
  end
end
