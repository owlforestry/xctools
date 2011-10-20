require 'ios-box/config'
require 'rubygems'
require 'yaml'
require 'grit'
require 'plist'

module Ios::Box
  class IOSBox
    attr_reader :config, :cache, :version

    def initialize
      # @config = Config.load
      @config = Config.new ".iosbox"
      
      @cache = Cache.load
      @version = Version.new(self)
    end
    
    def project_dir
      if ENV['XCODE_VERSION_ACTUAL']
        pdir = ENV['PROJECT_DIR']
      else
        # Do we have buildcache?
        if cache[:latest]
          configuration = cache[:latest]
          pdir = cache[configuration][:project_dir]
        else
          raise "Build cache has not been filled, please build project."
        end
      end

      pdir
    end
    
    def plist
      if ENV['XCODE_VERSION_ACTUAL']
        file = File.join(ENV['PROJECT_DIR'], ENV['INFOPLIST_FILE'])
      else
        # Do we have buildcache?
        if cache[:latest]
          configuration = cache[:latest]
          file = File.join(cache[configuration][:project_dir], cache[configuration][:infoplist_file])
        else
          raise "Build cache has not been filled, please build project."
        end
      end
      
      file
    end
    
    def git
      @git ||= Grit::Repo.new(project_dir)
    end
    
    
    class Version
      attr_reader :iosbox

      def initialize(iosbox)
        @iosbox = iosbox
      end

      def load
        # Return cached version
        return @version if @version
        
        # Detect our commit hash
        # git = Grit::Repo.new(iosbox.project_dir)
        pl = Plist::parse_xml(iosbox.plist)

        # Build normal version hash
        @version  = {
          :short  => pl["CFBundleShortVersionString"],
          :bundle => pl["CFBundleVersion"],
          :commit => iosbox.git.commit("HEAD").id_abbrev,
          :build  => pl["IBBuildNumber"],
        }

        # Build technical version number
        if (m = pl["CFBundleShortVersionString"].match(/(\d+)\.(\d+)(\.(\d+))?/))
          @version[:major] = Integer(m[1]) if m[1]
          @version[:minor] = Integer(m[2]) if m[2]
          @version[:patch] = Integer(m[4]) if m[4]
          @version[:technical] = @version[:major] + @version[:minor] / 100.0 + @version[:patch] / 10000.0
        end

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
      
      def to_a
        (@version ||= load).to_a
      end
      
      def marketing_version
        load unless @version
        "%d.%d%s" % [ @version[:major], @version[:minor], @version[:patch] ? ".#{@version[:patch]}" : "" ]
      end
      
      def bundle_version
        load unless @version
        
        # Build our components
        comp = {
          "M" => @version[:major],
          "m" => @version[:minor],
          "p" => @version[:patch],
          "P" => @version[:patch] ? ".#{@version[:patch]}" : "",
          "b" => @version[:build],
          "S" => marketing_version,
          "V" => @version[:major] * 10 + @version[:minor],
          "v" => @version[:major] * 100 + @version[:minor] * 10 + (@version[:patch] ? @version[:patch] : 0),
          "x" => begin
            prj_begin = Time.now
            if (iosbox.config.first_revision)
              prj_begin = iosbox.git.commit(iosbox.config.first_revision).authored_date
            elsif (iosbox.config.first_date)
              prj_begin = iosbox.config.first_date
            else
              prj_begin = iosbox.git.log.last.authored_date
            end
            
            months = ((Time.now.month + 12 * Time.now.year) - (prj_begin.month + 12 * prj_begin.year))
            "%d%02d" % [months, Time.now.day]
          end,
        }
        compre = Regexp.new("[" + comp.keys.join("") + "]")
        
        @version[:bundle] = (iosbox.config.bundle_version_style || "x").gsub(compre) do |s|
          comp[s]
        end
      end
      
      def bump_build(buildnum = nil)
        # Fetch current build number (project version)
        pl = Plist::parse_xml(iosbox.plist)
        # pl["CFBundleShortVersionString"] = verstr
        # pl.save_plist(plist)

        if buildnum.nil?
          build = (pl["IBBuildNumber"] || 0) + 1
        else
          build = buildnum
        end

        pl["IBBuildNumber"] = build
        pl["CFBundleVersion"] = bundle_version
        pl.save_plist(iosbox.plist)
        
        # Commit plist
        if iosbox.config['autocommit']
          iosbox.git.add iosbox.plist
          iosbox.git.commit "Bumped build number"
        end
        
        
        puts "Build number increased to #{build}"
      end

      def set_marketing(verstr)
        pl = Plist::parse_xml(iosbox.plist)
        pl["CFBundleShortVersionString"] = verstr
        pl.save_plist(iosbox.plist)
        
        puts "New marketing version #{marketing_version}"
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
        
        pl = Plist::parse_xml(iosbox.plist)
        pl["CFBundleShortVersionString"] = marketing_version
        pl.save_plist(iosbox.plist)
        
        puts "New marketing version #{marketing_version}"
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
