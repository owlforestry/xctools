require 'yaml'

module Ios
  module Box
    class Config
      def initialize(file = nil)
        @data = {}
        @file = file
        
        if !file.nil? and File.exists?(file)
          @data = YAML.load(File.read(file))
        end
      end
      
      def save(file = nil)
        File.open(file || @file, 'w') {|io| io.puts @data.to_yaml }
      end
      
      def to_a
        @data.to_a
      end
      
      def method_missing(method, *args, &block)
        if method[-1] == "="
          if args.length == 1
            @data[method[0..-2]] = args[0]
          end
        else
          @data[method]
        end
      end
    end
  end
end
