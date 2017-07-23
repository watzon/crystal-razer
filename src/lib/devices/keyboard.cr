require "./razer-device"
require "../interface"
require "../constants"

module Razer::Devices
  class RazerKeyboard < RazerDevice
    def initialize(serial : String, vid_pid = nil, daemon_dbus = nil)
      super(serial, vid_pid, daemon_dbus)

      # Keyboard specific capabilities
      @capabilities[:game_mode_led] = has_feature("razer.device.led.gamemode")
      @capabilities[:macro_mode_led] = has_feature("razer.device.led.macromode", "setMacroMode")
      @capabilities[:macro_mode_led_effect] = has_feature("razer.device.led.macromode", "setMacroEffect")
      @capabilities[:macro_tartarus_mode_modifier] = has_feature("razer.device.macro", "setModeModifier")

      if has(:game_mode_led)
        @dbus_interfaces[:game_mode_led] = Razer::Interface.new(@dbus, "razer.device.led.gamemode")
      end

      if has(:macro_mode_led)
        @dbus_interfaces[:macro_mode_led] = Razer::Interface.new(@dbus, "razer.device.led.macromode")
      end
    end

    # Get the game mode LED state
    def game_mode_led : Bool
      if has(:game_mode_led)
        return @dbus_interfaces[:game_mode_led].getGameMode.as(Bool)
      end

      false
    end

    # Set the game mode LED state
    def game_mode_led=(value : Bool)
      if has(:game_mode_led)
        @dbus_interfaces[:game_mode_led].setGameMode(value)
      end
    end

    # Get the macro mode LED state
    def macro_mode_led : Bool
      if has(:macro_mode_led)
        return @dbus_interfaces[:macro_mode_led].gerMacroMode.as(Bool)
      end

      false
    end

    # Set the macro mode LED state
    def macro_mode_led=(value : Bool)
      if has(:macro_mode_led)
        @dbus_interfaces[:macro_mode_led].setMacroMode(value)
      end
    end

    # Get the macro LED effect
    def macro_mode_led_effect : Int32
      if has(:macro_mode_led_effect)
        return @dbus_interfaces[:macro_mode_led].getMacroEffect.as(Int32)
      end

      false
    end

    # Set the macro LED effect
    def macro_mode_led_effect=(value : Int32)
      if has(:macro_mode_led_effect) && [Razer::MACRO_LED_STATIC, Razer::MACRO_LED_BLINK].includes?(value)
        return @dbus_interfaces[:macro_mode_led].setMacroEffect(value)
      end
    end
  end

  DEVICE_PID_MAP = {} of Int32 => RazerDevice.class

  class RazerKeyboardFactory < BaseDeviceFactory
    def self.get_device(serial : String, vid_pid = nil, daemon_dbus = nil)
      if vid_pid.nil?
        pid = 0xFFFF
      else
        pid = vid_pid[1]
      end

      device_class = DEVICE_PID_MAP.fetch(pid, RazerKeyboard)
      device_class.new(serial, vid_pid, daemon_dbus)
    end
  end
end
