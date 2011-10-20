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
        @namespace = namespace
        
        @iosbox = IOSBox.new
        define
      end
      
    private
      def define
        namespace(@namespace) do
          desc "Shows current version information"
          task :version do
          end
          
          desc "Bumps version"
          task :bump, :version do |t, args|
            puts args.inspect
            # config = Config.load
            puts config.inspect
          end
          
          namespace :bump do
            desc "Increases build number"
            task :build do |t, args|

            end
          end
          
          namespace :build do
            desc "Execute build preparation"
            task :prepare => ["build:cache", "version"] do
              require_xcode
              
              version = @iosbox.get_version
              
              # Calculate build number (displayed)
              # Inject information to Info.plist
              product_plist = File.join(ENV['BUILT_PRODUCTS_DIR'], ENV['INFOPLIST_PATH'])
              # Convert PList to XML
              `/usr/bin/plutil -convert xml1 \"#{product_plist}\"`
              pl = Plist::parse_xml(product_plist)
              if (pl)
                # pl["CFBundleVersion"] = @config._bundle_version
                # pl["IBBuildNum"] = @config._build_number
                pl["IBBuildDate"] = Time.new.strftime("%a %e %b %Y %H:%M:%S %Z %z")
                pl["IBBuildType"] = ENV['CONFIGURATION']
                pl["GCGitCommitHash"] = version[:commit] # for hoptoadapp
                pl.save_plist(product_plist)
              end
              # Convert PList back to binary
              `/usr/bin/plutil -convert binary1 \"#{product_plist}\"`
              
            end
            
            desc "Update build cache"
            task :cache do
              cache = IOSBox::Cache.load
              
              # Save our environment variables
              if ENV["CONFIGURATION"]
                configuration = ENV["CONFIGURATION"].downcase.to_sym
                cache[configuration] ||= {}
                cache[:latest] = configuration
                ["BUILT_PRODUCTS_DIR", "BUILD_DIR", "CONFIGURATION", "CONFIGURATION_BUILD_DIR",
                  "PROJECT_DIR", "INFOPLIST_FILE", "TARGET_NAME"].each do |v|
                  cache[configuration][v.downcase.to_sym] = ENV[v]
                end
              end
              
              cache.save
            end
          end
        end
      end
      
      def require_xcode
        raise "This task must be run in XCode Environment" unless ENV['XCODE_VERSION_ACTUAL']
      end
    end
  end
end
