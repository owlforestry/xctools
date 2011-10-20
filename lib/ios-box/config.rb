module Ios
  module Box
    class Config
      attr_accessor :project
      attr_reader :targets

      def self.load(file = ".iosbox")
        config = self.new
        config.instance_eval(File.read(file), file)
        config
      end
      
      def initialize
        @targets = []
        @project = nil
      end
      
      def config
        self
      end
    end
  end
end
