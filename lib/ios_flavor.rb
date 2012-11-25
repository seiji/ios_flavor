require "ios_flavor/version"
require "ios_flavor/cli"
require "ios_flavor/dsl"
require "ios_flavor/ext"

module IosFlavor
  def self.read_file (file)
    File.open(file, "rb") { |f| f.read }
  end

  def self.root
    File.expand_path '../..', __FILE__
  end

  def self.bin
    File.join root, 'bin'
  end

  def self.lib
    File.join root, 'lib'
  end

  def self.templates
    File.join root, 'templates'
  end
end
