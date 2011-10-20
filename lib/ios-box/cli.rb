require 'ios-box/tools'
require 'ios-box/iosbox'
require 'thor'
require 'pbxproject'

module Ios
  module Box
    class CLI < Thor
      include Thor::Actions
      
      desc "version CMD [options]", "Version mungle commands"
      def version(cmd, *args)
        Tools::Version.new(options).send(cmd, *args)
      end
      
      desc "integrate [PROJECT]", "Integrates ios-box with project, by default first founded"
      def integrate(project = nil)
        shell = Thor::Shell::Basic.new
        
        # Find our project
        if project.nil?
          project = Dir["*.xcodeproj"].first
        end
        
        unless File.exists?(project) and File.directory?(project)
          shell.error "Project #{project} is not valid."
          exit
        end
        
        shell.say "Integrating to project #{project}"
        
        # Detect if having existing Rakefile
        tasks = <<-END
#
# ios-box integration
# https://github.com/owl-forestry/ios-box
#
$LOAD_PATH.unshift('#{File.expand_path(File.join(File.dirname(__FILE__), '..'))}')
require "ios-box/tasks"

Ios::Box::Tasks.new do |config|
  config.project = '#{project}'
  # end of configuration block
end
        END
        
        if File.exists?("Rakefile")
          # Detect if already appended
          # Append to Rakefile our tasks
          append_to_file "Rakefile", tasks
        else
          create_file "Rakefile", tasks
        end
        
        shell.say "Finish integration by executing ios-box addtarget command."
      end
      
      desc "addtarget [target] [project]", "Configures given target to execute ios-box at build."
      def addtarget(target = nil, project = nil)
        # Find our project file, either from command-line or just using first one
        xcode = project || Dir["*.xcodeproj"].first
        raise "Cannot find project.pbxproj in #{xcode}" unless File.file? "#{xcode}/project.pbxproj"
        
        # Load our project file
        pbx = PBXProject::PBXProject.new :file => "#{xcode}/project.pbxproj"
        pbx.parse
        
        # If target missing, fetch first target
        unless target.nil?
          tgt = pbx.find_item :name => target, :type => PBXProject::PBXTypes::PBXNativeTarget
          raise "Cannot find named target #{target}" if tgt.nil?
          target = tgt
        else target.nil?
          targets = pbx.find_item(:type => PBXProject::PBXTypes::PBXNativeTarget)
          raise "Cannot find any targets from project" if targets.empty?
          
          target = targets.first
        end
        
        # Add new build phase
        # Add build:prepare task to build phases
        # Try to find build phases
        prebuilds = pbx.find_item(:type => PBXProject::PBXTypes::PBXShellScriptBuildPhase) || []
        prebuilds.select! do |c|
          c.shellScript.value.match /iosbox:build:prepare/
        end
        if prebuilds.empty?        
          initPhase = PBXProject::PBXTypes::PBXShellScriptBuildPhase.new(
            :shellPath => '/bin/sh',
            :shellScript => "\"(cd $PROJECT_DIR; rake iosbox:build:prepare)\"",
            :showEnvVarsInLog => 0
            )
          pbx.add_item initPhase
        else
          initPhase = prebuilds.first
        end
        
        # Inject buildphase to target
        # Add to target
        target.add_build_phase initPhase, 0
        
        # Write project file
        pbx.write_to :file => "#{xcode}/project.pbxproj"
        
        # Append target to config block
        insert_into_file "Rakefile", "  config.targets << '#{target.name.value}'\n", :before => "  # end of configuration block"
      end
    end
  end
end
