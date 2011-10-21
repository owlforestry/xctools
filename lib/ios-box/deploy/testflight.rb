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

        if response.code == 200
          pl = Plist::parse_xml(response.to_str)

          puts "Build Deployed."
          puts "See it at: #{pl['config_url']}"

          notify(
            :name  => "Build Deployed",
            :title => "Build Deployed",
          :text  => "Build Deployed to Testflight.\nSee build at #{pl['config_url']}")
        end

        puts "Complete build at #{pl['config_url']}"
      end
    end
  end
end
