require 'yaml'
require 'ostruct'

module IOSBox
  class Config < OpenStruct
    attr_accessor :file

    def self.load(file)
      if File.exists?(file)
        config = self.new(YAML.load(File.read(file)))
      else
        config = self.new
      end

      config.file = file
      config
    end

    def save(file = nil)
      puts "Saving config to #{file || @file}"
      File.open(file || @file, 'w') {|io| io.puts @table.to_yaml }
    end

    def to_a
      res = []
      @table.collect do |k,v|
        if v.kind_of?(Hash)
          res << ["#{k.to_s}:", ""]
          v.each {|k,v| res << ["  #{k.to_s}", v]}
        else
          res << [k.to_s, v]
        end
      end
      res
    end
  end
end
