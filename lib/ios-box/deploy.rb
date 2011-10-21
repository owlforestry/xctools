require 'plist'
require 'zip/zip'

module IOSBox
  module Deploy
    autoload :Testflight, 'ios-box/deploy/testflight'
    
    class Deployer
      def create_ipa(path)
        puts "Creating IPA from path #{path}..."
        
        # Check for missing plist
        raise "Archive info.plist is missing" unless File.exists?(File.join(path, "Info.plist"))
        pl = Plist::parse_xml(File.join(path, "Info.plist"))
        raise "Invalid XCArchive version" unless pl['ArchiveVersion'] == 1

        app_path = pl['ApplicationProperties']['ApplicationPath']
        app_name = File.basename(app_path, File.extname(app_path))
        ipa_name = File.join(path, "Products", "#{app_name}.ipa")
        puts "Compressing #{app_path}"
        if File.exists?(ipa_name)
          File.unlink(ipa_name)
        end
        
        Zip::ZipFile.open(ipa_name, Zip::ZipFile::CREATE) do |zip|
          Dir["#{File.join(path, "Products", app_path)}/**/*"].each do |entry|
            e_name = entry.gsub(/#{File.join(path, "Products", app_path)}\//, '')
            e_name = "Payload/#{app_name}.app/#{e_name}"
            zip.add e_name, entry
          end
        end
        
        ipa_name
      end
      
      def create_dsym(path)
        puts "Creating Zipped dSYM from path #{path}..."
        
        # Check for missing plist
        raise "Archive info.plist is missing" unless File.exists?(File.join(path, "Info.plist"))
        pl = Plist::parse_xml(File.join(path, "Info.plist"))
        raise "Invalid XCArchive version" unless pl['ArchiveVersion'] == 1

        app_path = pl['ApplicationProperties']['ApplicationPath']
        app_name = File.basename(app_path)
        dsym_name = File.join(path, "dSYMs", "#{app_name}.dSYM.zip")

        if File.exists?(dsym_name)
          File.unlink(dsym_name)
        end
        
        Zip::ZipFile.open(dsym_name, Zip::ZipFile::CREATE) do |zip|
          dsym_path = File.join(path, "dSYMs")
          puts "Path #{dsym_path}"
          Dir["#{File.join(dsym_path, "#{app_name}.dSYM")}/**/*"].each do |entry|
            e_name = entry.gsub(/#{dsym_path}\//, '')
            zip.add e_name, entry
          end
        end
        
        dsym_name        
      end
    end
  end
end
