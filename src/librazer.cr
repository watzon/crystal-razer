require "dbus"
require "dbus/introspect"
require "json"
require "./razer/*"

module Razer
  class DeviceManager
    getter :devices, :daemon_version

    @dbus : DBus::Object
    @dbus_daemon : Interface
    @dbus_devices : Interface
    @device_serials : Array(DBus::Type)

    def initialize
      bus = DBus::Bus.new
      dest = bus.destination("org.razer")
      @dbus = dest.object("/org/razer")
      @dbus_daemon = Interface.new(@dbus, "razer.daemon")
      @dbus_devices = Interface.new(@dbus, "razer.devices")
      @device_serials = @dbus_devices.getDevices.as(Array(DBus::Type))
      @devices = [] of Devices::RazerDevice
      @daemon_version = @dbus_daemon.version.as(String)

      @device_serials.each do |serial|
        device = RazerDeviceFactory.get_device(serial.as(String))
        @devices << device
      end
    end

    def get_object(path)
      @dbus.object(path)
    end

    # Stop the daemon via DBus call.
    # Daemon will have to be restarted manually
    def stop_daemon
      @dbus_daemon.stop
    end

    def turn_off_screensaver
      @dbus_devices.getOnOffScreensaver.as(Bool)
    end

    # Enable or disable the logic to turn off the device when the screen locks
    #
    # If true, when the screensaver is active or the device is locked the device's
    # brightness will be set to 0.
    # When the screensaver is inactive the device's brightness will be restored.
    def turn_off_screensaver=(value : Bool)
      @dbus_devices.enableTurnOffOnScreensaver(value)
    end

    def sync_effects
      @dbus_devices.getSyncEffects.as(Bool)
    end

    # Enable or disable the syncing of effects between devices
    # If sync is enabled, whenever an effect is set then it will be set on all other
    # devices if the effect is available or a similar effect if it is not.
    def sync_effects=(value : Bool)
      @dbus_devices.syncEffects(value)
    end

    def supported_devices
      data = @dbus_daemon.supportedDevices.as(String)
      JSON.parse(data).as_h
    end
  end
end

# dm = Razer::DeviceManager.new
# kb = dm.devices[0]
# fx = Razer::RazerFX.new(kb.serial, kb.capabilities)
