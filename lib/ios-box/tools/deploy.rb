require 'ios-box/deploy'
require 'pbxproject'
require 'nokogiri'

module IOSBox
  module Tools
    class Deploy < Thor
      include Thor::Actions

      desc "add PROVIDER", "Configures deployment targets"
      def add(provider)
        iosbox = IOSBox.new
        pbx = PBXProject::PBXProject.new :file => File.join(iosbox.project_dir, iosbox.config.project, "project.pbxproj")
        pbx.parse

        # Find all configuration lists and check if we have already Ad Hoc configuration
        cfglists = pbx.find_item :type => PBXProject::PBXTypes::XCConfigurationList
        cfglists.each do |cfg|
          if cfg.buildConfigurations.select {|bc| bc.comment == "Ad Hoc"}.empty?
            puts "Copy Release => Ad Hoc"
            release = cfg.buildConfigurations.select {|bc| bc.comment == "Release"}.first.value
            bc = pbx.find_item :guid => release, :type => PBXProject::PBXTypes::XCBuildConfiguration
            adhoc = PBXProject::PBXTypes::XCBuildConfiguration.new
            adhoc.comment = "Ad Hoc"
            adhoc.name = PBXProject::PBXTypes::BasicValue.new(:value => '"Ad Hoc"')
            adhoc.buildSettings = bc.buildSettings
            pbx.add_item adhoc

            cfg.buildConfigurations << PBXProject::PBXTypes::BasicValue.new(:value => adhoc.guid, :comment => "Ad Hoc")
            cfg.defaultConfigurationName = "Release"
          end
        end

        pbx.write_to :file => File.join(iosbox.project_dir, iosbox.config.project, "project.pbxproj")

        # Copy scheme
        xcuserdata = File.join(iosbox.project_dir, iosbox.config.project, "xcuserdata", "#{ENV['USER']}.xcuserdatad")
        scheme = File.open(Dir[File.join(xcuserdata, "xcschemes", "*.xcscheme")].first)
        deploy = File.join(xcuserdata, "xcschemes", "Deploy.xcscheme")
        doc = Nokogiri::XML(scheme)

        # Get identifier
        blueprint_id = doc.xpath("//BuildableReference").first.attr("BlueprintIdentifier")

        # Change configuration of Archive
        action = doc.xpath("//ArchiveAction").first
        action.attribute("buildConfiguration").value = "Ad Hoc"
        # Add Post Action
        Nokogiri::XML::Builder.with(action) do |xml|
          xml.PostActions {
            xml.ExecutionAction(:ActionType => "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction") {
              xml.ActionContent(:title => "Run Script", :scriptText=> "(cd $PROJECT_DIR; ios-box deploy #{provider})") {
                xml.EnvironmentBuildable {
                  xml.BuildableReference(
                    :BuildableIdentifier => "primary",
                    :BlueprintIdentifier => "C0B33A571451827A000B80A2",
                    :BuildableName       => "ios.app",
                    :BlueprintName       => "ios",
                    :ReferencedContainer => "container:ios.xcodeproj")
                }
              }
            }
          }
        end

        File.open(deploy, 'w') {|io| io.puts doc.to_xml }
      end

      desc "testflight", "Deploys latest built archive to TestFlight"
      method_option :notes, :type => :string, :desc => "Supply build notes. If a file, notes are read from given file."
      method_option :distribution, :type => :array, :desc => "Distribution list to deploy"
      method_option :notify, :type => :boolean, :default => true, :desc => "Notify testers of new build"
      method_option :replace, :type => :boolean, :default => true, :desc => "Replace existing build"
      def testflight
        iosbox = IOSBox.new

        tf = ::IOSBox::Deploy::Testflight.new

        # Do we have archive path in buildcache
        if ENV['XCODE_VERSION_ACTUAL'] and ENV['CONFIGURATION'] == "Ad Hoc"
          # Always use fresh data if ran from XCode
          prod_path = ENV['ARCHIVE_PATH']
          # Update cache
          puts iosbox.cache.inspect
          iosbox.cache[:"ad hoc"][:archive_path] = ENV['ARCHIVE_PATH']
          iosbox.cache.save
        elsif iosbox.cache[:"ad hoc"][:archive_path]
          # Otherwise use build cache if exists
          prod_path = iosbox.cache[:"ad hoc"][:archive_path]
        else
          # Otherwise, require Xcode
          require_xcode
        end

        # Check that we have required keys
        if iosbox.config.testflight['apitoken'].nil?
          shell.error "Please set TestFlight API token (ios-box config set testflight_apitoken XXXXXX)"
        end
        if iosbox.config.testflight['teamtoken'].nil?
          shell.error "Please set TestFlight Team token (ios-box config set testflight_teamtoken XXXXXX)"
        end
        raise "Missing API tokens" if iosbox.config.testflight['apitoken'].nil? or iosbox.config.testflight['teamtoken'].nil?

        puts "Deploying to TestFlight... Please wait..."
        ipa = tf.create_ipa prod_path
        dsym = tf.create_dsym prod_path

        # Creating build notes
        if options['notes'].nil?
          if iosbox.config.deploy['autonotes']
            # Get last deployment
            last_deployed = iosbox.config.testflight['lastdeploy'] || begin
            iosbox.git.log.last.id
          end
          # Get git changelog
          notes = ""
          iosbox.git.commits_between(last_deployed, 'HEAD').each do |commit|
            notes << commit.authored_date.to_s + "\n"
            notes << commit.authored_date.to_s.length.times.inject("") { |i,c| i + "=" } + "\n"
            notes << commit.message + "\n"
          end
        else
          # Try to find TextMate
          mate = %x{which mate}.strip
          if File.exists?(mate)
            f = Tempfile.new('notes')
            f.write "Replace this with build notes."; f.close
            %x{#{mate} --wait #{f.path}}
               puts File.read(f)
               end
               end
               else
                 if File.exists?(options['notes'])
                   notes = File.read(options['notes'])
                 else
                   notes = options['notes']
                 end
               end

               tf.deploy :file => ipa,
               :apitoken     => iosbox.config.testflight['apitoken'],
               :teamtoken    => iosbox.config.testflight['teamtoken'],
               :notes        => notes,
               :dsym         => dsym,
               :distribution => options['distribution'],
               :notify       => options['notify'],
               :replace      => options['replace'],
               :growl        => iosbox.config.growl
               end

               private
                 def require_xcode
                   raise "This task must be run in XCode Environment" unless ENV['XCODE_VERSION_ACTUAL']
                 end

                 end
                 end
                 end
