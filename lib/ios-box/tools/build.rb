module Ios
  module Box
    module Tools
      class Build < Thor
        
        desc "prepare", "Prepare build environment from XCode"
        def prepare
          # Make sure we are in XCode environment
          require_xcode
          
          # Update build cache
          update_cache
          
          version = IOSBox.new.version
          
          # Calculate build number (displayed)
          puts "TODO: build number"
          
          # Inject information to Info.plist
          product_plist = File.join(ENV['BUILT_PRODUCTS_DIR'], ENV['INFOPLIST_PATH'])
          
          # Convert PList to XML
          `/usr/bin/plutil -convert xml1 \"#{product_plist}\"`
          pl = Plist::parse_xml(product_plist)
          if (pl)
            # pl["CFBundleVersion"] = @config._bundle_version
            pl["IBBuildNum"] = version[:build]
            pl["IBBuildDate"] = Time.new.strftime("%a %e %b %Y %H:%M:%S %Z %z")
            pl["IBBuildType"] = ENV['CONFIGURATION']
            pl["GCGitCommitHash"] = version[:commit] # for airbrake
            pl.save_plist(product_plist)
          end
          # Convert PList back to binary
          `/usr/bin/plutil -convert binary1 \"#{product_plist}\"`
        end
        
        private
        
        def update_cache
          cache = IOSBox.new.cache
          
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
        
        def require_xcode
          raise "This task must be run in XCode Environment" unless ENV['XCODE_VERSION_ACTUAL']
        end
      end
    end
  end
end
