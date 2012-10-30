# IosFlavor

add xcode project system frameworks

## Installation

Add this line to your application's Gemfile:

    gem 'ios_flavor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ios_flavor

## Usage

$ cd $XCODE_PROJECT

$ cat <<EOS > Flavorfile
platform 'iPhoneOS', '6.0'
framework 'MobileCoreServices'
EOS

$ ios_flavor

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
