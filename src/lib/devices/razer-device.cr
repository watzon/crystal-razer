require "xml"
require "json"
require "dbus"
require "dbus/introspect"
require "../interface"

module Razer::Devices
  # Base device class for all razer devices
  class RazerDevice
    getter :name, :type, :firmware_version, :driver_version, :serial, :capabilities, :fx

    @vid_pid : Array(DBus::Type)?
    @dbus_interfaces : Hash(Symbol, Razer::Interface)
    @name : String?
    @type : String?
    @firmware_version : String?
    @driver_version : String?
    @urls : Hash(String, JSON::Type)?
    @available_features : Hash(String, Array(String))
    @capabilities : Hash(Symbol, Bool)

    def initialize(@serial : String, @vid_pid = nil, daemon_dbus = nil)
      if daemon_dbus.nil?
        session_bus = DeviceManager.new
        daemon_dbus = session_bus.get_object("/org/razer/device/#{serial}")
      end

      @dbus = daemon_dbus.as(DBus::Object)
      @dbus_interfaces = {
        :device     => Razer::Interface.new(@dbus, "razer.device.misc"),
        :brightness => Razer::Interface.new(@dbus, "razer.device.lighting.brightness"),
      }
      @name = @dbus_interfaces[:device].getDeviceName.as(String)
      @type = @dbus_interfaces[:device].getDeviceType.as(String)
      @firmware_version = @dbus_interfaces[:device].getFirmware.as(String)
      @driver_version = @dbus_interfaces[:device].getDriverVersion.as(String)
      @has_dedicated_macro = nil
      @urls = nil
      @vid_pid ||= @dbus_interfaces[:device].getVidPid.as(Array(DBus::Type))
      @available_features = get_available_features
      @capabilities = {
        :name             => true,
        :type             => true,
        :firmware_version => true,
        :serial           => true,
        :brightness       => has_feature("razer.device.lighting.brightness"),
        :macro_logic      => has_feature("razer.device.macro"),

        # Default device is a chroma, so lighting capabilities should be expected
        :lighting               => has_feature("razer.device.lighting.chroma"),
        :lighting_breath_single => has_feature("razer.device.lighting.chroma", "setBreathSingle"),
        :lighting_breath_dual   => has_feature("razer.device.lighting.chroma", "setBreathDual"),
        :lighting_breath_triple => has_feature("razer.device.lighting.chroma", "setBreathTriple"),
        :lighting_breath_random => has_feature("razer.device.lighting.chroma", "setBreathRandom"),
        :lighting_wave          => has_feature("razer.device.lighting.chroma", "setWave"),
        :lighting_reactive      => has_feature("razer.device.lighting.chroma", "setReactive"),
        :lighting_none          => has_feature("razer.device.lighting.chroma", "setNone"),
        :lighting_spectrum      => has_feature("razer.device.lighting.chroma", "setSpectrum"),
        :lighting_static        => has_feature("razer.device.lighting.chroma", "setStatic"),

        :lighting_starlight_single => has_feature("razer.device.lighting.chroma", "setStarlightSingle"),
        :lighting_starlight_dual   => has_feature("razer.device.lighting.chroma", "setStarlightDual"),
        :lighting_starlight_random => has_feature("razer.device.lighting.chroma", "setStarlightRandom"),

        :lighting_ripple              => has_feature("razer.device.lighting.chroma", "setRipple"),
        :lighting_ripple_random_color => has_feature("razer.device.lighting.chroma", "setRippleRandomColour"),

        :lighting_pulsate => has_feature("razer.device.lighting.chroma", "setPulsate"),

        # Check if device has an LED matrix
        :lighting_led_matrix => @dbus_interfaces[:device].hasMatrix.as(Bool),
        :lighting_led_single => has_feature("razer.device.lighting.chroma", "setKey"),

        # Mouse lighting attributes
        :lighting_logo               => has_feature("razer.device.lighting.logo"),
        :lighting_logo_active        => has_feature("razer.device.lighting.logo", "setLogoActive"),
        :lighting_logo_blinking      => has_feature("razer.device.lighting.logo", "setLogoBlinking"),
        :lighting_logo_brightness    => has_feature("razer.device.lighting.logo", "setLogoBrightness"),
        :lighting_logo_pulsate       => has_feature("razer.device.lighting.logo", "setLogoPulsate"),
        :lighting_logo_spectrum      => has_feature("razer.device.lighting.logo", "setLogoSpectrum"),
        :lighting_logo_static        => has_feature("razer.device.lighting.logo", "setLogoStatic"),
        :lighting_logo_none          => has_feature("razer.device.lighting.logo", "setLogoNone"),
        :lighting_logo_reactive      => has_feature("razer.device.lighting.logo", "setLogoReactive"),
        :lighting_logo_breath_single => has_feature("razer.device.lighting.logo", "setLogoBreathSingle"),
        :lighting_logo_breath_dual   => has_feature("razer.device.lighting.logo", "setLogoBreathDual"),
        :lighting_logo_breath_random => has_feature("razer.device.lighting.logo", "setLogoBreathRandom"),

        :lighting_scroll               => has_feature("razer.device.lighting.scroll"),
        :lighting_scroll_active        => has_feature("razer.device.lighting.scroll", "setScrollActive"),
        :lighting_scroll_blinking      => has_feature("razer.device.lighting.scroll", "setScrollBlinking"),
        :lighting_scroll_brightness    => has_feature("razer.device.lighting.scroll", "setScrollBrightness"),
        :lighting_scroll_pulsate       => has_feature("razer.device.lighting.scroll", "setScrollPulsate"),
        :lighting_scroll_spectrum      => has_feature("razer.device.lighting.scroll", "setScrollSpectrum"),
        :lighting_scroll_static        => has_feature("razer.device.lighting.scroll", "setScrollStatic"),
        :lighting_scroll_none          => has_feature("razer.device.lighting.scroll", "setScrollNone"),
        :lighting_scroll_reactive      => has_feature("razer.device.lighting.scroll", "setScrollReactive"),
        :lighting_scroll_breath_single => has_feature("razer.device.lighting.scroll", "setScrollBreathSingle"),
        :lighting_scroll_breath_dual   => has_feature("razer.device.lighting.scroll", "setScrollBreathDual"),
        :lighting_scroll_breath_random => has_feature("razer.device.lighting.scroll", "setScrollBreathRandom"),

        :lighting_backlight        => has_feature("razer.device.lighting.backlight"),
        :lighting_backlight_active => has_feature("razer.device.lighting.backlight", "setBacklightActive"),
      }
      @fx = RazerFX.new(@serial, @capabilities, @dbus)
    end

    def has(capability : Symbol) : Bool
      @capabilities[capability]
    end

    def has_feature(object_path : String, method_name : String? | Tuple? = nil) : Bool
      if method_name.nil?
        return @available_features.has_key?(object_path)
      elsif method_name.is_a?(String)
        return @available_features[object_path].includes?(method_name) if @available_features.has_key?(object_path)
        return false
      elsif method_name.is_a?(Tuple)
        result = true
        method_name.each do |name|
          result &= has_feature(object_path, name)
        end
        return result
      else
        return false
      end
    end

    def get_available_features : Hash(String, Array(String))
      introspect_interface = Razer::Interface.new(@dbus, "org.freedesktop.DBus.Introspectable")
      xml_spec = introspect_interface.call("Introspect").as(String)

      root = XML.parse(xml_spec)
      nodes = root.xpath_nodes("node/interface[@name!='org.freedesktop.DBus.Introspectable']")

      interfaces = {} of String => Array(String)

      nodes.each do |child|
        current_interface = child["name"]
        current_interface_methods = [] of String

        child.children.each do |method|
          if method.name == "method"
            current_interface_methods << method["name"]
          end
        end

        interfaces[current_interface] = current_interface_methods
      end

      return interfaces
    end

    # Get device brightness
    def brightness
      return @dbus_interfaces[:brightness].getBrightness.as(Float)
    end

    # Set device brightness
    #
    # ```crystal
    # device.brightness = 80.0
    # ```
    def brightness=(val : Float)
      if val < 0.0 || val > 100.0
        raise Exception.new("Value must be between 0.0 and 100.0. Got #{val}")
      end

      @dbus_interfaces[:brightness].setBrightness(val)
    end

    # Check if the device has dedicated macro keys
    def dedicated_macro
      if @has_dedicated_macro.nil?
        @has_dedicated_macro = @dbus_interfaces[:device].hasDedicatedMacroKeys.as(Bool)
      end

      @has_dedicated_macro
    end

    # Urls for store links and images
    def razer_urls
      if @urls.nil?
        @urls = JSON.parse(@dbus_interfaces[:device].getRazerUrls.as(String)).as_h
      end

      @urls
    end
  end

  abstract class BaseDeviceFactory
    def self.get_device(serial : String, daemon_dbus = nil) : RazerDevice
      raise Error.new("Not implimented")
    end
  end
end
