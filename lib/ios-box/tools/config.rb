module IOSBox
  module Tools
    class Config < Thor
      desc "show", "Displays current configuration information"
      def show
        shell.print_table IOSBox.new.config.to_a
      end

      desc "set key value", "Sets certain key to value value"
      def set(key, value)
        if ["true", "yes"].include?(value.downcase)
          value = true
        elsif ["false", "no"].include?(value.downcase)
          value = false
        end

        config = IOSBox.new.config
        # Split config
        category, key = key.split(/\./)
        if key.nil?
          config.send("#{category}=", value)
        else
          if !config.send(category).kind_of?(Hash)
            config.send("#{category}=", {})
          end
          config.send(category).send(:[]=, key, value)
        end

        # config.testflight = {}
        # config.testflight['apikey'] = 'XXXX'
        # # config.send("#{key}=", value)
        config.save
      end
    end
  end
end
