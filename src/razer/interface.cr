require "dbus"
require "dbus/introspect"

module Razer
  class Interface
    def initialize(@daemon_dbus : DBus::Object, @address : String)
    end

    def interface
      @daemon_dbus.interface(@address)
    end

    def call(method)
      interface.call(method).reply[0]
    end

    macro method_missing(call)
        def {{call.name.id}}{% if call.args.size > 0 %}({{ *call.args.map { |x| "#{x.id}, ".id } }}){% end %}
            res = interface.call("{{call.name.id}}"{% if call.args.size > 0 %}, {{call.args}}{% end %}).reply
            if res.is_a?(Array)
              if res.size == 1
                return res[0]
              elsif res.empty?
                return nil
              end
            end

            return res
        end
    end
  end
end
