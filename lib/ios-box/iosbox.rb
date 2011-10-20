require 'ios-box/config'
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

    def get_version
      # iOS code
      # XCode environment?
      # Load buildcache if exists
      if ENV['XCODE_VERSION_ACTUAL']
        plist_file = File.join(ENV['PROJECT_DIR'], ENV['INFOPLIST_FILE'])
        project_dir = ENV['PROJECT_DIR']
      else
        # Do we have buildcache?
        if cache[:latest]
          configuration = cache[:latest]
          plist_file = File.join(cache[configuration][:project_dir], cache[configuration][:infoplist_file])
          project_dir = cache[configuration][:project_dir]
        else
          raise "Build cache has not been filled, please build project."
        end
      end

      # Detect our commit hash
      git = Grit::Repo.new("#{project_dir}")

      plist = Plist::parse_xml(plist_file)

      # Build normal version hash
      ver = {
        :short  => plist["CFBundleShortVersionString"],
        :bundle => plist["CFBundleVersion"],
        :commit => git.commit("HEAD").id_abbrev,
      }

      # Build technical version number
      if (m = plist["CFBundleShortVersionString"].match(/(\d+)\.(\d+)(\.(\d+))?/))
        ver[:major] = Integer(m[1]) if m[1]
        ver[:minor] = Integer(m[2]) if m[2]
        ver[:patch] = Integer(m[4]) if m[4]
        ver[:technical] = ver[:major] + ((ver[:minor] * 100) / 1000.0)
        if ver[:patch]
          ver[:technical] += ((ver[:patch] > 10) ? ver[:patch] : ver[:patch] * 10) / 1000.0
        end
      end

      # Fetch current build number (project version)
      # Check if we have build number in cache
      unless cache[:build_number]
        puts "Project: #{config.project}"
        pbx = PBXProject::PBXProject.new :file => File.join(config.project, "project.pbxproj")
        pbx.parse

        config.targets.each do |target|
          target = pbx.find_item :name => target, :type => PBXProject::PBXTypes::PBXNativeTarget
          cl = pbx.find_item :guid => target.buildConfigurationList.value, :type => PBXProject::PBXTypes::XCConfigurationList
          cl.buildConfigurations.each do |bc|
            bc = pbx.find_item :guid => bc.value, :type => PBXProject::PBXTypes::XCBuildConfiguration
            # binding.pry
            if bc.buildSettings["CURRENT_PROJECT_VERSION"]
              cache[:build_number] = bc.buildSettings["CURRENT_PROJECT_VERSION"].value
              break
            end
          end

          break if cache[:build_number]
        end
        save_cache cache
      end
      ver[:build_number] = cache[:build_number]

      ver
    end
    
    class Version
      attr_reader :iosbox
      
      def initialize(iosbox)
        @iosbox = iosbox
      end
      
      def bump(build = nil)
        # Fetch current build number (project version)
        # Check if we have build number in cache
        puts "Project: #{iosbox.config.project}"
        pbx = PBXProject::PBXProject.new :file => File.join(iosbox.config.project, "project.pbxproj")
        pbx.parse

        iosbox.config.targets.each do |target|
          target = pbx.find_item :name => target, :type => PBXProject::PBXTypes::PBXNativeTarget
          cl = pbx.find_item :guid => target.buildConfigurationList.value, :type => PBXProject::PBXTypes::XCConfigurationList
          cl.buildConfigurations.each do |bc|
            bc = pbx.find_item :guid => bc.value, :type => PBXProject::PBXTypes::XCBuildConfiguration
            # binding.pry
            if bc.buildSettings["CURRENT_PROJECT_VERSION"]
              num = Integer(bc.buildSettings["CURRENT_PROJECT_VERSION"].value.gsub(/"/, ''))
            else
              num = 0
            end
            num += 1 # Increase by one
            iosbox.cache[:build_number] = num
            if bc.buildSettings["CURRENT_PROJECT_VERSION"]
              bc.buildSettings["CURRENT_PROJECT_VERSION"].value = "\"#{num}\""
            else
              bc.buildSettings["CURRENT_PROJECT_VERSION"] = PBXProject::PBXTypes::BasicValue.new :value => "\"#{num}\""
            end
          end

          break if iosbox.cache[:build_number]
        end

        iosbox.cache.save
        pbx.write_to :file => File.join(iosbox.config.project, "project.pbxproj")
        puts "Build number increased to #{iosbox.cache[:build_number]}"
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
end
