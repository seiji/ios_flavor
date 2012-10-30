
module IosFlavor
  class DSL
    attr_reader :platform_name
    attr_reader :version
    attr_reader :frameworks

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
    end

    def platform(name='iPhoneOS', version='6.0')                # iPhoneOS, 
      @platform = name
      @version  = version
    end

    def framework(name)
      @frameworks.push(name)
    end
  end
end
