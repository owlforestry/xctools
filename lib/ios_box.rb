require 'rake/tasklib'
require 'pbxproject'
require 'yaml'
require 'ostruct'
require 'grit'
require 'plist'

module IosBox
  class Tasks < ::Rake::TaskLib
    def initialize(namespace = :iosbox, &block)
      @config = Config.new(
        :configuration => "Adhoc",
        :build_style => :months,
        :bundle_version_style => "V.b",
        :buildCache => ".buildCache"
      )
      yield @config
      
      # Load build cache
      @buildCache = BuildCache.load(@config.buildCache) || BuildCache.new
      @namespace = namespace
      define
    end

    class BuildCache
      def self.load file = ".buildCache"
        return unless File.file?(file)
        YAML.load_file(file)
      end
      
      def save file = ".buildCache"
        File.open(file, 'w') { |io| YAML.dump(self, io) }
      end
    end
    
    class Config < OpenStruct
      def initialize args
        super
        self.plist = File.join(ENV['PROJECT_DIR'] || '', ENV['INFOPLIST_FILE'] || '')
      end
    end
    
    private

    def define
      # General namespace
      namespace(@namespace) do
        desc "Integrates IosBox to XCode build phases"
        task :integrate do
          # Get our xcodeproject from config or find it
          xcode = @config.project || Dir["*.xcodeproj"].first
          
          raise "Cannot find project.pbxproj in #{xcode}" unless File.file? "#{xcode}/project.pbxproj"
          pbx = PBXProject::PBXProject.new :file => "#{xcode}/project.pbxproj"
          pbx.parse
          
          # Add build:prepare task to build phases
          initPhase = PBXProject::PBXTypes::PBXShellScriptBuildPhase.new :shellPath => '/bin/sh', :shellScript => "\"(cd $PROJECT_DIR; rake #{@namespace}:build:prepare)\""
          pbx.add_item initPhase
          
          # Add to target
          target = pbx.find_item :name => @config.target, :type => PBXProject::PBXTypes::PBXNativeTarget
          target.add_build_phase initPhase, 0
          
          # Save our project file
          pbx.write_to :file => "#{xcode}/project.pbxproj"
        end
        
        # Version mungle
        desc "Returns current version string"
        task :version do
          @plist = Plist::parse_xml(@config.plist)
          @config._short_version = @plist["CFBundleShortVersionString"]
          puts " Short Version: #{@config._short_version}"
        end
        
        namespace :version do
          @ver = {:major => nil, :minor => nil, :patch => nil}
          def _prepare
            @git = Grit::Repo.new("#{ENV['PROJECT_DIR']}")
            @config._commit = @git.commit("HEAD").id_abbrev
            
            @plist = Plist::parse_xml(@config.plist)
            if (m = @plist["CFBundleShortVersionString"].match(/(\d+)\.(\d+)(\.(\d+))?/))
              @ver[:major] = Integer(m[1]) if m[1]
              @ver[:minor] = Integer(m[2]) if m[2]
              @ver[:patch] = Integer(m[4]) if m[4]
            end
          end
          
          def _write_back
            @plist = Plist::parse_xml(@config.plist) unless @plist
            ver_str = "%d.%d%s" % [ @ver[:major], @ver[:minor], @ver[:patch] ? ".#{@ver[:patch]}" : "" ]
            @plist["CFBundleShortVersionString"] = ver_str
            @plist.save_plist(@config.plist)
          end
  
          desc "Generates Bundle Version"
          task :bundlever => ["version", "version:buildnum"] do
            # Build our components
            comp = {
              "M" => @ver[:major],
              "m" => @ver[:minor],
              "p" => @ver[:patch],
              "P" => @ver[:patch] ? ".#{@ver[:patch]}" : "",
              "b" => @config._build_number,
              "S" => @config._short_version,
              "V" => @ver[:major] * 10 + @ver[:minor],
              "v" => @ver[:major] * 100 + @ver[:minor] * 10 + (@ver[:patch] ? @ver[:patch] : 0),
              "g" => @config._commit,
            }
            compre = Regexp.new("[" + comp.keys.join("") + "]")
            
            style = case @config.bundle_version_style
            when :short_version
              "S"
            when :buildnum
              "b"
            when :githash
              "g"
            else
              @config.bundle_version_style
            end
            
            @config._bundle_version = style.gsub(compre) do |s|
              comp[s]
            end
            
            puts "Bundle Version: #{@config._bundle_version}"
          end
          
          desc "Generate new build number, depending on selected scheme"
          task :buildnum do
            _prepare
            buildnum = case @config.build_style
            when :months
              # Open repository and find out
              prj_begin = Time.now
              if (@config.first_revision)
                prj_begin = @git.commit(@config.first_revision).authored_date
              elsif (@config.first_date)
                prj_begin = @config.first_date
              else
                prj_begin = @git.log.last.authored_date
              end
              
              months = ((Time.now.month + 12 * Time.now.year) - (prj_begin.month + 12 * prj_begin.year))
              "%d%02d" % [months, Time.now.day]
            end
            
            @config._build_number = buildnum
            puts "  Build number: #{buildnum}"
          end
          
          desc "Writes exact version number"
          task :write, :version do |t, args|
            @plist = Plist::parse_xml(@config.plist)
            @plist["CFBundleShortVersionString"] = args[:version]
            @plist.save_plist(@config.plist)
            puts "Short Version: #{args[:version]}"
          end
          
          desc "Bumps version up"
          task :bump do
            _prepare
            
            # if we have patch, bump it up
            if (@ver[:patch])
              @ver[:patch] += 1
            elsif (@ver[:minor])
              @ver[:minor] += 1
            else
              @ver[:major] += 1
            end
            _write_back
            puts "Bumped Version: " + "%d.%d%s" % [ @ver[:major], @ver[:minor], @ver[:patch] ? ".#{@ver[:patch]}" : "" ]
          end
          
          namespace :bump do
            desc "Bumps major version up"
            task :major do
              _prepare
              @ver[:major] = @ver[:major] ? @ver[:major] + 1 : 1              
              @ver[:minor] = 0
              @ver[:patch] = nil
              _write_back
              puts "Bumped Version: " + "%d.%d%s" % [ @ver[:major], @ver[:minor], @ver[:patch] ? ".#{@ver[:patch]}" : "" ]
            end
            
            desc "Bumps minor version up"
            task :minor do
              _prepare
              @ver[:minor] = @ver[:minor] ? @ver[:minor] + 1 : 1              
              @ver[:patch] = nil
              _write_back
              puts "Bumped Version: " + "%d.%d%s" % [ @ver[:major], @ver[:minor], @ver[:patch] ? ".#{@ver[:patch]}" : "" ]
            end

            desc "Bumps patch version up"
            task :patch do
              _prepare
              @ver[:patch] = @ver[:patch] ? @ver[:patch] + 1 : 1              
              _write_back
              puts "Bumped Version: " + "%d.%d%s" % [ @ver[:major], @ver[:minor], @ver[:patch] ? ".#{@ver[:patch]}" : "" ]
            end
        end
          
        end
        
        namespace :build do
          
          desc "Prepares build environment"
          task :prepare => ["version:bundlever"] do
            # Save our environment variables
            ["BUILT_PRODUCTS_DIR", "BUILD_DIR", "CONFIGURATION", "CONFIGURATION_BUILD_DIR",
              "PROJECT_DIR", "INFOPLIST_FILE", "TARGET_NAME"].each { |v|
              @buildCache.instance_variable_set("@#{v.downcase}", ENV[v])
            }
            @buildCache.save
            
            # Save version info
            product_plist = File.join(ENV['BUILT_PRODUCTS_DIR'], ENV['INFOPLIST_PATH'])
            `/usr/bin/plutil -convert xml1 \"#{product_plist}\"`
            pl = Plist::parse_xml(product_plist)
            if (pl)
              pl["CFBundleVersion"] = @config._bundle_version
              pl["IBBuildNum"] = @config._build_number
              pl["IBBuildDate"] = Time.new.strftime("%a %e %b %Y %H:%M:%S %Z %z")
              pl["IBBuildType"] = ENV['CONFIGURATION']
              pl["GCGitCommitHash"] = @config._commit # for hoptoadapp
              pl.save_plist(product_plist)
            end
            `/usr/bin/plutil -convert binary1 \"#{product_plist}\"`
          end
        end
      end
    end
  end
end