require 'ios-box/deploy'

module IOSBox
  module Tools
    class Deploy < Thor
      desc "testflight", "Deploys latest built archive to TestFlight"
      method_option :notes,
        :type    => :string,
        :desc    => "Supply build notes. If a file, notes are read from given file."
      method_option :distribution,
        :type    => :array,
        :desc    => "Distribution list to deploy"
      method_option :notify,
        :type    => :boolean,
        :default => true,
        :desc    => "Notify testers of new build"
      method_option :replace,
        :type    => :boolean,
        :default => true,
        :desc    => "Replace existing build"
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
