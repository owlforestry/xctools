require 'ios-box/config'
require 'ios-box/tools'
require 'ios-box/iosbox'
require 'thor'
require 'pbxproject'

module Ios
  module Box
    class CLI < Thor
      include Thor::Actions
      
      desc "version COMMAND", "Version related subcommands"
      subcommand "version", Tools::Version
      
      desc "build COMMAND", "Build related subcommands"
      subcommand "build", Tools::Build
      
      desc "config COMMAND", "Configuration related subcommands"
      subcommand "config", Tools::Config
      
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
        
        # Find our project file, either from command-line or just using first one
        xcode = project || Dir["*.xcodeproj"].first
        raise "Cannot find project.pbxproj in #{xcode}" unless File.file? "#{xcode}/project.pbxproj"
        
        # Load our project file
        pbx = PBXProject::PBXProject.new :file => "#{xcode}/project.pbxproj"
        pbx.parse
        
        # If target missing, fetch first target
        # Find all targets
        targets = pbx.find_item :type => PBXProject::PBXTypes::PBXNativeTarget
        if targets.nil? or targets.empty?
          raise "XCode project does not have any targets!"
        end
        
        # Generate build phase
        # Try to find build phases
        # prebuilds = pbx.find_item(:type => PBXProject::PBXTypes::PBXShellScriptBuildPhase) || []
        # prebuilds.select! do |c|
        #   !c.comment.match(/ios-box prepare/).nil?
        # end
        # 
        prebuilds = [] # Always add new build phase
        if prebuilds.empty?        
          initPhase = PBXProject::PBXTypes::PBXShellScriptBuildPhase.new(
            :shellPath => '/bin/sh',
            :shellScript => "\"(cd $PROJECT_DIR; #{%x{which ios-box}.strip} build prepare)\"",
            :showEnvVarsInLog => 0,
            :name => '"ios-box prepare"'
            )
          initPhase.comment = "ios-box prepare"

          pbx.add_item initPhase
        else
          initPhase = prebuilds.first
        end
        
        targets.each do |target|
          if shell.yes?("Integrate with target #{target.name.value}? [yn]")
            # Inject buildphase to target
            # Add to target
            target.add_build_phase initPhase, 0
          end
        end
        
        # Create iosbox configuration file
        config = Config.new
        config.project = project
        config.targets = targets.collect{|c| c.name.value}
        config.save(".iosbox")

        # Append buildcache to gitignore
        send((File.exists?(".gitignore") ? :append_to_file : :create_file), ".gitignore", ".buildcache\n")
        
        # Write project file
        pbx.write_to :file => "#{xcode}/project.pbxproj"
      end
    end
  end
end
