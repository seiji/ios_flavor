require "ios_flavor/version"
require "ios_flavor/cli"
require "ios_flavor/dsl"

module IosFlavor
  def self.read_file (file)
    File.open(file, "rb") { |f| f.read }
  end
end
