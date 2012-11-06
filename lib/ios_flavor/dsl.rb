
module IosFlavor

  class FlavorError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class FlavorfileError < FlavorError ;status_code(2) end

  class DSL
    attr_reader :platform_name
    attr_reader :version
    attr_reader :frameworks
    attr_reader :build_settings

    def self.evaluate(flavorfile)
      flavor = new
      flavor.instance_eval(IosFlavor.read_file(flavorfile.to_s), flavorfile.to_s, 1)
      flavor
    rescue ScriptError, RegexpError, NameError, ArgumentError => e
      raise FlavorfileError, "There was an error in your Flavorfile,"
    end

    def initialize
      @platform_name = 'iPhoneOS'
      @version       = '6.0'
      @frameworks = []
      @settings = {
        :common => {}
      }
    end

    def platform(name='iPhoneOS', version='6.0')                # iPhoneOS, 
      @platform = name
      @version  = version
    end

    def framework(name)
      @frameworks.push(name)
    end

    def settings(build_settings)
      @build_settings = build_settings
    end
  end
end
