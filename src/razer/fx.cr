module Razer
  abstract class BaseRazerFX
    @dbus : DBus::Object
    @capabilities : Hash(Symbol, Bool)

    def initialize(serial : String, @capabilities : Hash(Symbol, Bool), daemon_dbus : DBus::Object? = nil)
      if daemon_dbus.nil?
        session_bus = DBus::Bus.new
        daemon_dbus = session_bus.object("org.razer", "/org/razer/device/#{serial}")
      end

      @dbus = daemon_dbus.as(DBus::Object)
    end

    # Convenience function to check capability
    def has(capability : Symbol) : Bool
      @capabilities[capability]
    end
  end

  class RazerFX < BaseRazerFX
    @advanced : RazerAdvancedFX?
    @custom_lighting_dbus : Interface?
    @misc : MiscLighting?

    def initialize(serial : String, capabilities : Hash(Symbol, Bool), daemon_dbus : DBus::Object? = nil, matrix_dims = {-1, -1})
      super(serial, capabilities, daemon_dbus)

      @lighting_dbus = Interface.new(@dbus, "razer.device.lighting.chroma")

      # Make sure all dimensions exist. If any value in matrix_dims is falsy, returns false
      if has(:lighting_led_matrix) && matrix_dims.any? { |i| !!i }
        @advanced = RazerAdvancedFX.new(serial, @capabilities, @dbus, matrix_dims)
      end

      if has(:lighting_led_matrix) && has(:lighting_ripple)
        @custom_lighting_dbus = Interface.new(@dbus, "razer.device.lighting.cutsom")
      end

      @misc = MiscLighting.new(serial, @capabilities, @dbus)
    end

    def none : Bool
      if has :lighting_none
        @lighting_dbus.setNone

        return true
      end

      false
    end

    def spectrum : Bool
      if has :lighting_spectrum
        @lighting_dbus.setSpectrum

        return true
      end

      false
    end

    def wave(direction : Int32) : Bool
      if has :lighting_wave
        if [WAVE_RIGHT, WAVE_LEFT].includes?(direction)
          @lighting_dbus.setWave(direction)
          return true
        else
          raise Exception.new("Direction must be one of (0x01, 0x02). Got #{direction}")
        end
      end

      false
    end

    def static(color : RGB) : Bool
      if has :lighting_static
        @lighting_dbus.setStatic(*color.to_t)
        return true
      end

      false
    end

    def reactive(color : RGB, time : Int32) : Bool
      if has :lighting_reactive
        if [REACTIVE_500MS, REACTIVE_1000MS, REACTIVE_1500MS, REACTIVE_2000MS].includes?(time)
          @lighting_dbus.setReactive(*color.to_t, time)
          return true
        else
          raise Exception.new("Time must be one of (#{REACTIVE_500MS}, #{REACTIVE_1000MS}, #{REACTIVE_1500MS}, #{REACTIVE_2000MS}). Got #{time}")
        end
      end

      false
    end

    def breath_single(color : RGB) : Bool
      if has :lighting_breath_single
        @lighting_dbus.setBreathSingle(*color.to_t)
        return true
      end

      false
    end

    def breath_dual(color1, color2 : RGB) : Bool
      if has :lighting_breath_dual
        @lighting_dbus.setBreathDual(*color1.to_t, *color2.to_t)
        return true
      end

      false
    end

    def breath_triple(color1, color2, color3 : RGB) : Bool
      if has :lighting_breath_triple
        @lighting_dbus.setBreathDual(*color1.to_t, *color2.to_t, *color3.to_t)
        return true
      end

      false
    end

    def breath_random : Bool
      if has :lighting_breath_random
        @lighting_dbus.setBreathRandom
        return true
      end

      false
    end

    def ripple(color : RGB, refresh_rate : Float = 0.05) : Bool
      if has :lighting_ripple
        @lighting_dbus.setRipple(*color.to_t, refresh_rate)
        return true
      end

      false
    end

    def ripple_random(refresh_rate : Float = 0.05) : Bool
      if has :lighting_ripple_random_color
        @lighting_dbus.setRippleRandomColour(refresh_rate) # Freaking brits and their colour
        return true
      end

      false
    end

    def starlight_single(color : RGB, time : Int32) : Bool
      if has :lighting_starlight_single
        if [STARLIGHT_FAST, STARLIGHT_NORMAL, STARLIGHT_SLOW].includes?(time)
          @lighting_dbus.setStarlightSingle(*color.to_t, time)
          return true
        else
          raise Exception.new("Time must be one of (#{STARLIGHT_FAST}, #{STARLIGHT_NORMAL}, #{STARLIGHT_SLOW}). Got #{time}")
        end
      end

      false
    end

    def starlight_dual(color1 : RGB, color2 : RGB, time : Int32) : Bool
      if has :lighting_starlight_dual
        if [STARLIGHT_FAST, STARLIGHT_NORMAL, STARLIGHT_SLOW].includes?(time)
          @lighting_dbus.setStarlightSingle(*color1.to_t, *color2.to_a, time)
          return true
        else
          raise Exception.new("Time must be one of (#{STARLIGHT_FAST}, #{STARLIGHT_NORMAL}, #{STARLIGHT_SLOW}). Got #{time}")
        end
      end

      false
    end

    def starlight_random(time : Int32) : Bool
      if has :lighting_starlight_single
        if [STARLIGHT_FAST, STARLIGHT_NORMAL, STARLIGHT_SLOW].includes?(time)
          @lighting_dbus.setStarlightRandom(time)
          return true
        else
          raise Exception.new("Time must be one of (#{STARLIGHT_FAST}, #{STARLIGHT_NORMAL}, #{STARLIGHT_SLOW}). Got #{time}")
        end
      end

      false
    end
  end

  class RazerAdvancedFX < BaseRazerFX
    def initialize(serial : String, capabilities : Hash(Symbol, Bool), daemon_dbus : DBus::Object?, matrix_dims = {-1, -1})
      super(serial, capabilities, daemon_dbus)
    end
  end

  class MiscLighting < BaseRazerFX
    def initialize(serial : String, capabilities : Hash(Symbol, Bool), daemon_dbus : DBus::Object?)
      super(serial, capabilities, daemon_dbus)
    end
  end
end
