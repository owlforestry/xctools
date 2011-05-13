module IosBox
  class BuildCache
    def init config
      # Fill our config object
      # But only if it hasn't been initialized yet and not in XCode env
      if (config.project_dir.nil? && ENV['XCODE_VERSION_ACTUAL'].nil?)
        config.project_dir = @project_dir
        config.infoplist_file = @infoplist_file
        config.plist = File.join(@project_dir, @infoplist_file) unless @project_dir.nil?
      end
    end
  
    def self.load file = ".buildCache"
      return unless File.file?(file)
      YAML.load_file(file)
    end
  
    def save file = ".buildCache"
      File.open(file, 'w') { |io| YAML.dump(self, io) }
    end
  
    def method_missing(m, *args, &block)
      if (args.length > 0)
        self.class.class_eval do
          define_method("#{m.to_s[0, m.to_s.length - 1]}") do
            instance_variable_get("@#{m.to_s[0, m.to_s.length - 1]}")
          end

          define_method("#{m.to_s[0, m.to_s.length - 1]}=") do |val|
            instance_variable_set("@#{m.to_s[0, m.to_s.length - 1]}", val)
          end
        end
        return instance_variable_set("@#{m.to_s[0, m.to_s.length - 1]}", args[0])
      end

      self.class.class_eval do
        define_method(m) do
          instance_variable_get("@#{m}")
        end
      end
      return instance_variable_get("@#{m}")
    end
  end
end
