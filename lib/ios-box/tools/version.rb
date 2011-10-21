module IOSBox
  module Tools
    class Version < Thor
      desc "show", "Displays current version information"
      def show
        version = IOSBox.new.version


        puts "  Short Version: #{version[:short]}"
        puts " Bundle Version: #{version[:bundle]}"
        puts "      Technical: %1.4f" % version[:technical]
        puts "   Build Number: #{version[:build]}"
        puts "         Commit: #{version[:commit]}"
      end

      desc "build [BUILDNUM]", "Increments current build number or sets it to defined."
      def build(buildnum = nil)
        IOSBox.new.version.bump_build(buildnum)
      end

      desc "set VERSION", "Sets new marketing version"
      def set(ver)
        IOSBox.new.version.set_marketing(ver)
      end

      desc "bump [major|minor]", "Bumps marketings version by one"
      def bump(type = :patch)
        IOSBox.new.version.bump_marketing(type.to_s.downcase.to_sym)
      end
    end
  end
end
