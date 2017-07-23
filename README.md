# crystal-razer

Facilitate control of your Razer chroma devices.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystal-razer:
    github: watzon/crystal-razer
```

## Usage

```crystal
require "crystal-razer"

# Create a new DeviceManager instance
dm = Razer::DeviceManager.new

# List connected Razer devices
pp dm.devices #=> [#<Razer::Devices::RazerKeyboard:0x561974a06f80 ...]

# Select a particular device
kbd = dm.devices[0].as(Razer::Devices.Keyboard) # Not ideal having to use `.as()`, but it's all that works for now

# List available features for the device
pp kbd.get_available_features   #=>     [#<Razer::Devices::RazerKeyboard:0x563b4e057f80
                                #           @available_features=
                                #              {"razer.device.misc" =>
                                #                ["getSerial",
                                #                 "suspendDevice",
                                #                 "getDeviceMode",
                                #                 "getRazerUrls",
                                #                 "setDeviceMode"
                                #                 ...]
                                #              }
                                #       ]

# Set the keyboard's color to a static color
green = Razer::RGB.from(:razer_green)
kbd.fx.static(green)
```


## Development

Just submit a PR if you want to add any features. You can check '[terrycain/razer-drivers](https://github.com/terrycain/razer-drivers)' for help, as that is the library that I got everything from.

## Contributing

1. Fork it ( https://github.com/watzon/crystal-razer/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
