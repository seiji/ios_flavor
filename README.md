# IosFlavor

add xcode project some features

## Feature

- Add Frameworks

- Add Build Settings

- Versioning (use agvtool)

- Default Layout 

## Installation

Add this line to your application's Gemfile:

    gem 'ios_flavor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ios_flavor

## Usage

    $ cd $XCODE_PROJECT

generate flavor template

    $ flavor init

setup

    $ flavor install

You will now have access to a variety of tasks such as clean and build.

    $ rake -T
    rake build              # Build the application
    rake clean              # Cleans compiled application
    rake specs              # Runs through the specs to ensure functionality
    rake version:bump       # Bumps up the current bundle version
    rake version:bundle     # Show bundle version (CFBundleVersion)
    rake version:marketing  # Show marketing version (CFBundleShortVersionString)
    rake version:write      # Explicitly set the BUNDLE_VERSION or MARKETING_VERSION
    rake xcode:env          # Show build settings
    rake xcode:list         # List the targets and configurations in a project
    rake xcode:schemes      # List available schemes
    rake xcode:sdks         # List available sdks

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
