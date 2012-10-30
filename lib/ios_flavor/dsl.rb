
module IosFlavor
  class DSL
    attr_reader :frameworks

    def self.evaluate(flavorfile)
      flavor = new
      flavor.instance_eval(IosFlavor.read_file(flavorfile.to_s), flavorfile.to_s, 1)
      flavor
    end

    def initialize
      @frameworks = []
    end

    def framework(name)
      @frameworks.push(name)
    end
  end
end
