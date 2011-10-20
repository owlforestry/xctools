module Ios
  module Box
    module Tools
      class Config < Thor
        desc "show", "Displays current configuration information"
        def show
          config = IOSBox.new.config
          
          shell.print_table config.to_a          
        end
        
        desc "set key value", "Sets certain key to value value"
        def set(key, value)
          if ["true", "yes"].include?(value.downcase)
            value = true
          elsif ["false", "no"].include?(value.downcase)
            value = false
          end
          
          config = IOSBox.new.config
          config.send("#{key}=", value)
          config.save
        end
      end
    end
  end
end
