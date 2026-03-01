class Npc
  attr_reader :name, :tile_x, :tile_y

  def initialize(name:, tile_x:, tile_y:, image:, tile_size: 32)
    @name = name
    @tile_x = tile_x
    @tile_y = tile_y
    @image = image
    @tile_size = tile_size
    @phase = rand * Math::PI * 2.0
  end

  def draw(camera_x, camera_y, viewport_x, viewport_y, z = 6)
    base_x = viewport_x + @tile_x * @tile_size - camera_x
    base_y = viewport_y + @tile_y * @tile_size - camera_y
    bob = Math.sin((Gosu.milliseconds / 220.0) + @phase) * 1.2

    draw_x = base_x + (@tile_size - @image.width) / 2
    draw_y = base_y + (@tile_size - @image.height) + bob
    @image.draw(draw_x, draw_y, z)
  end

  def auto_move()
    @tile_x += rand(-1..1)
    @tile_y += rand(-1..1)
    if @tile_x < 0
      @tile_x = 0
    end
    if @tile_y < 0
      @tile_y = 0
    end
  end
end
