require "dbus"
require "dbus/introspect"
require "./interface"
require "./devices/*"

DEVICE_MAP = {
  # "firefly"  => nil,
  "keyboard" => Razer::Devices::RazerKeyboardFactory,
  # "mouse"    => nil,
  "tartarus" => Razer::Devices::RazerKeyboardFactory,
}

module Razer
  class RazerDeviceFactory
    # Factory for turning a serial into a class
    #
    # Device factory, will return a class fit for the device in question. The DEVICE_MAP mapping above
    # can contain a device_type => DeviceClass or DeviceFactory, this allows us to specify raw device classes
    # if there is only one model (like Firefly) or a factory for the keyboards (so we can differentiate between
    # old blackwidows and chromas). If the device is not in the device mapping then the factory will default
    # to a raw RazerDevice.
    def self.get_device(serial, vid_pid = nil, daemon_dbus = nil)
      if daemon_dbus.nil?
        session_bus = DBus::Bus.new
        daemon_dbus = session_bus.object("org.razer", "/org/razer/device/#{serial}")
      end

      device_dbus = Razer::Interface.new(daemon_dbus, "razer.device.misc")
      device_type = device_dbus.getDeviceType.as(String)           # => "keyboard"
      device_vid_pid = device_dbus.getVidPid.as(Array(DBus::Type)) # => [5426, 542]

      if DEVICE_MAP.has_key?(device_type) && !DEVICE_MAP[device_type].nil?
        device_class = DEVICE_MAP[device_type]
        if device_class.responds_to?(:get_device)
          # Use the device factory
          device = device_class.get_device(serial, device_vid_pid, daemon_dbus)
        else
          # Use the device class
          device = device_class.new(serial, device_vid_pid, daemon_dbus)
        end
      else
        # No mapping. Default to RazerDevice
        device = Razer::Devices::RazerDevice.new(serial, device_vid_pid, daemon_dbus)
      end

      device
    end
  end
end
