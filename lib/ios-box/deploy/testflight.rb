require 'rest_client'

module IOSBox
  module Deploy
    class Testflight < Deployer
      def deploy(opts)
        puts opts.to_yaml

        response = RestClient.post 'http://testflightapp.com/api/builds.plist',
          :api_token          => opts[:apitoken],
          :team_token         => opts[:teamtoken],
          :file               => File.new(opts[:file], 'rb'),
          :notes              => opts[:notes],
          :dsym               => (File.exists?(opts[:dsym]) ? File.new(opts[:dsym], 'rb') : nil),
          :distribution_lists => opts[:distribution],
          :notify             => opts[:notify],
          :replace            => opts[:replace]

        if opts[:growl]
          begin
            require 'ruby_gntp'
            
            growl = GNTP.new("ios-box")
            growl.register({:notifications => [
                              {:name => "Build Deployed", :enabled => true},
                              {:name => "Build Failed", :enabled => true}
            ]})
          rescue LoadError
            opts[:growl] = false
            puts "Please install ruby_gntp gem if you want to enable Growl notifications."
          end
        end
        if response.code == 200
          pl = Plist::parse_xml(response.to_str)

          puts "Build Deployed."
          puts "See it at: #{pl['config_url']}"

          if opts[:growl]
            growl.notify(
              :name    => "Build Deployed",
              :title => "Build Deployed",
              :text  => "Build Deployed to Testflight.\nSee build at #{pl['config_url']}",
            )
          end
        end

        puts "Complete build at #{pl['config_url']}"
      end
    end
  end
end
