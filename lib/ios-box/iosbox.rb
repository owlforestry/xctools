require 'ios-box/config'
require 'rubygems'
require 'yaml'
require 'grit'
require 'plist'

module Ios::Box
  class IOSBox
    attr_reader :config, :cache, :version

    def initialize
      @config = Config.load
      @cache = Cache.load
      @version = Version.new(self)
    end

    class Version
      attr_reader :iosbox

      def initialize(iosbox)
        @iosbox = iosbox
      end

      def load
        # Return cached version
        return @version if @version
        
        # iOS code
        # XCode environment?
        # Load buildcache if exists
        if ENV['XCODE_VERSION_ACTUAL']
          plist_file = File.join(ENV['PROJECT_DIR'], ENV['INFOPLIST_FILE'])
          project_dir = ENV['PROJECT_DIR']
        else
          # Do we have buildcache?
          if iosbox.cache[:latest]
            configuration = iosbox.cache[:latest]
            plist_file = File.join(iosbox.cache[configuration][:project_dir], iosbox.cache[configuration][:infoplist_file])
            project_dir = iosbox.cache[configuration][:project_dir]
          else
            raise "Build cache has not been filled, please build project."
          end
        end

        # Detect our commit hash
        git = Grit::Repo.new("#{project_dir}")

        plist = Plist::parse_xml(plist_file)

        # Build normal version hash
        @version = {
          :short  => plist["CFBundleShortVersionString"],
          :bundle => plist["CFBundleVersion"],
          :commit => git.commit("HEAD").id_abbrev,
        }

        # Build technical version number
        if (m = plist["CFBundleShortVersionString"].match(/(\d+)\.(\d+)(\.(\d+))?/))
          @version[:major] = Integer(m[1]) if m[1]
          @version[:minor] = Integer(m[2]) if m[2]
          @version[:patch] = Integer(m[4]) if m[4]
          @version[:technical] = @version[:major] + ((@version[:minor] * 100) / 1000.0)
          if @version[:patch]
            @version[:technical] += ((@version[:patch] > 10) ? @version[:patch] : @version[:patch] * 10) / 1000.0
          end
        end

        # Fetch current build number (project version)
        # Check if we have build number in cache

        @version[:build_number] = fetch_build_number

        @version
      end

      def [](v)
        @version ||= load
        @version[v]
      end

      def []=(v, s)
        @version ||= load
        @version[v] = s
      end
      
      def marketing_version
        "%d.%d%s" % [ @version[:major], @version[:minor], @version[:patch] ? ".#{@version[:patch]}" : "" ]
      end
      
      def bump_build(buildnum = nil)
        # Fetch current build number (project version)
        # Check if we have build number in cache
        if buildnum.nil?
          build = (fetch_build_number || 0) + 1
        else
          build = buildnum
        end

        store_build_number(build)
        
        puts "Build number increased to #{iosbox.cache[:build_number]}"
      end

      def set_marketing(verstr)
        pl = Plist::parse_xml(plist)
        pl["CFBundleShortVersionString"] = verstr
        pl.save_plist(plist)
      end
      
      def bump_marketing(type = :patch)
        load
        
        if type == :major
          @version[:patch] = nil
          @version[:minor] = 0
          @version[:major] += 1
        elsif type == :minor
          @version[:patch] = nil
          @version[:minor] += 1
        elsif type == :patch
          @version[:patch] = (@version[:patch] || 0) + 1
        end
        
        pl = Plist::parse_xml(plist)
        pl["CFBundleShortVersionString"] = marketing_version
        pl.save_plist(plist)
        
        puts "New marketing version #{marketing_version}"
      end

      private
        def fetch_build_number
          unless iosbox.cache[:build_number]
            puts "Project: #{iosbox.config.project}"
            pbx = PBXProject::PBXProject.new :file => File.join(iosbox.config.project, "project.pbxproj")
            pbx.parse
            
            iosbox.config.targets.each do |target|
              target = pbx.find_item :name => target, :type => PBXProject::PBXTypes::PBXNativeTarget
              cl = pbx.find_item :guid => target.buildConfigurationList.value, :type => PBXProject::PBXTypes::XCConfigurationList
              cl.buildConfigurations.each do |bc|
                bc = pbx.find_item :guid => bc.value, :type => PBXProject::PBXTypes::XCBuildConfiguration

                if bc.buildSettings["CURRENT_PROJECT_VERSION"]
                  iosbox.cache[:build_number] = bc.buildSettings["CURRENT_PROJECT_VERSION"].value
                  break
                end
              end

              break if iosbox.cache[:build_number]
            end

            # Save build number to cache
            iosbox.cache.save
          end

          Integer(iosbox.cache[:build_number] || 0)
        end

        def store_build_number(build)
          puts "Project: #{iosbox.config.project}"
          pbx = PBXProject::PBXProject.new :file => File.join(iosbox.config.project, "project.pbxproj")
          pbx.parse

          iosbox.config.targets.each do |target|
            target = pbx.find_item :name => target, :type => PBXProject::PBXTypes::PBXNativeTarget
            cl = pbx.find_item :guid => target.buildConfigurationList.value, :type => PBXProject::PBXTypes::XCConfigurationList
            cl.buildConfigurations.each do |bc|
              bc = pbx.find_item :guid => bc.value, :type => PBXProject::PBXTypes::XCBuildConfiguration

              if bc.buildSettings["CURRENT_PROJECT_VERSION"]
                bc.buildSettings["CURRENT_PROJECT_VERSION"].value = "\"#{build}\""
              else
                bc.buildSettings["CURRENT_PROJECT_VERSION"] = PBXProject::PBXTypes::BasicValue.new :value => "\"#{build}\""
              end
            end
          end
          
          # Save build number to pbxproject and to cache
          pbx.write_to :file => File.join(iosbox.config.project, "project.pbxproj")
          iosbox.cache[:build_number] = build
          iosbox.cache.save
        end
        
        # Return plist file name
        def plist
          if ENV['XCODE_VERSION_ACTUAL']
            file = File.join(ENV['PROJECT_DIR'], ENV['INFOPLIST_FILE'])
          else
            # Do we have buildcache?
            if iosbox.cache[:latest]
              configuration = iosbox.cache[:latest]
              file = File.join(iosbox.cache[configuration][:project_dir], iosbox.cache[configuration][:infoplist_file])
            else
              raise "Build cache has not been filled, please build project."
            end
          end
          
          file
        end
    end
  end



  class Cache
    attr_accessor :cache

    def self.load(file = ".buildcache")
      cache = Cache.new

      if File.exists?(file)
        cache.cache = YAML.load(File.read(file))
      end

      cache
    end

    def initialize
      @cache = {}
    end

    def [](v)
      @cache[v]
    end

    def []=(v, s)
      @cache[v] = s
    end

    def save(file = ".buildcache")
      File.open(file, 'w') { |io| io.puts @cache.to_yaml }
    end
  end
end
