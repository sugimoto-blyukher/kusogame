require_relative "game_config"

class Player
  attr_reader :mx, :my

  def initialize(x, y, image_path, tile_size: GameConfig::TILE_SIZE)
    @mx = x
    @my = y
    @tile_size = tile_size
    @step_dx = 0
    @step_dy = 0
    @remaining_steps = 0
    @image = Gosu::Image.new(image_path)
  rescue StandardError => e
    warn "プレイヤー画像 '#{image_path}' の読み込みに失敗しました: #{e.message}"
    exit(1)
  end

  def update(input_x, input_y, map, collision_map)
    if @remaining_steps.positive?
      advance_step
      return true
    end

    return false if input_x + input_y == 0
    return false unless input_x == 0 || input_y == 0

    tile_x = @mx / @tile_size + input_x
    tile_y = @my / @tile_size + input_y

    can_move = map.in_bounds?(tile_x, tile_y) && collision_map[tile_x, tile_y] == 0
    return false unless can_move

    @step_dx = input_x * 4
    @step_dy = input_y * 4
    @remaining_steps = 8

    advance_step
    true
  end

  def draw(screen_x, screen_y, z = 30)
    draw_x = screen_x + (@tile_size - @image.width) / 2
    draw_y = screen_y + (@tile_size - @image.height)
    @image.draw(draw_x, draw_y, z)
  end

  def warp_to(tile_x, tile_y)
    @mx = tile_x * @tile_size
    @my = tile_y * @tile_size
    @step_dx = 0
    @step_dy = 0
    @remaining_steps = 0
  end

  private

  def advance_step
    @mx += @step_dx
    @my += @step_dy
    @remaining_steps -= 1
  end
end
