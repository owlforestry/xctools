module Ios
  module Box
    module Tools
      class Version < Tool
        def show
          version = @iosbox.get_version
          
          puts "  Short Version: #{version[:short]}"
          puts " Bundle Version: #{version[:bundle]}"
          puts "      Technical: %1.3f" % version[:technical]
          puts "   Build Number: #{version[:build_number]}"
          puts "         Commit: #{version[:commit]}"
        end
        
        def bump(build = nil)
          @iosbox.version.bump(build)
        end
      end
    end
  end
end
