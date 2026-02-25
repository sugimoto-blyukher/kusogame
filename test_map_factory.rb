require_relative "map"
require_relative "game_config"

module TestMapFactory
  module_function

  def build(tile_count, tile_offset)
    base_rows = Array.new(GameConfig::TEST_MAP_HEIGHT) do |y|
      Array.new(GameConfig::TEST_MAP_WIDTH) do |x|
        (x + y * GameConfig::TEST_MAP_WIDTH + tile_offset) % tile_count
      end
    end

    sub_rows = Array.new(GameConfig::TEST_MAP_HEIGHT) do |y|
      Array.new(GameConfig::TEST_MAP_WIDTH) do |x|
        next nil unless (x + y * 2 + tile_offset) % 11 == 0

        (x * 7 + y * 13 + tile_offset) % tile_count
      end
    end

    collision_rows = Array.new(GameConfig::TEST_MAP_HEIGHT) do |y|
      Array.new(GameConfig::TEST_MAP_WIDTH) do |x|
        border = x.zero? || y.zero? || x == GameConfig::TEST_MAP_WIDTH - 1 || y == GameConfig::TEST_MAP_HEIGHT - 1
        wall = (x % 8).zero? && y.between?(4, GameConfig::TEST_MAP_HEIGHT - 5)
        (border || wall) ? 1 : 0
      end
    end

    carve_passages(collision_rows)

    [
      Map.from_rows(base_rows),
      Map.from_rows(sub_rows),
      Map.from_rows(collision_rows)
    ]
  end

  def carve_passages(rows)
    (2...(GameConfig::TEST_MAP_HEIGHT - 2)).each do |y|
      rows[y][8] = 0
      rows[y][16] = 0
      rows[y][24] = 0
      rows[y][32] = 0 if GameConfig::TEST_MAP_WIDTH > 33
    end
  end
end
