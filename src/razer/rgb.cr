module Razer
  COLORS = {
    :white => {255, 255, 255},
    :black => {0, 0, 0},
    :red   => {255, 0, 0},
    :blue  => {0, 0, 255},
    :green => {0, 255, 0},
  }

  class RGB
    property :red, :green, :blue

    @red : Int32
    @green : Int32
    @blue : Int32

    def initialize(@red : Int32, @green : Int32, @blue : Int32)
      [@red, @green, @blue].each { |color| color = color.clamp(0, 255) }
    end

    def self.from(color : Symbol)
      if COLORS.has_key?(color)
        return RGB.new(*COLORS[color])
      else
        raise Exception.new("The color '#{color}' is not defined")
      end
    end

    def set(red, green, blue)
      @red = red
      @green = green
      @blue = blue
      self
    end

    def to_a
      [@red, @green, @blue]
    end

    def to_t
      {@red, @green, @blue}
    end

    def to_s
      "RGB{ #{@red}, #{@green}, #{@blue} }"
    end
  end
end
