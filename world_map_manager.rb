require_relative "map"
require_relative "game_config"

class WorldMapManager
  attr_reader :current_key, :base_map, :sub_map, :collision_map, :warps, :npcs

  def initialize(world_maps)
    @world_maps = world_maps
    @current_key = nil
    @base_map = nil
    @sub_map = nil
    @collision_map = nil
    @warps = []
    @npcs = []
    @spawn_tile = [0, 0]
  end

  def load!(map_key, spawn_override = nil)
    info = @world_maps.fetch(map_key)
    @current_key = map_key
    @base_map = Map.new(info[:file])
    @sub_map = build_empty_sub_map(@base_map)
    @warps = info[:warps]
    @npcs = info[:npcs] || []
    @collision_map = build_collision_map(@base_map, @warps)
    @spawn_tile = spawn_override || info[:spawn_tile]
  end

  def spawn_tile
    @spawn_tile
  end

  def transition_for(tile_x, tile_y)
    warp = @warps.find { |entry| entry[:tile] == [tile_x, tile_y] }
    return nil unless warp

    { to: warp[:to], spawn: warp[:spawn] }
  end

  private

  def build_empty_sub_map(base_map)
    rows = Array.new(base_map.size_y) { Array.new(base_map.size_x, nil) }
    Map.from_rows(rows)
  end

  def build_collision_map(base_map, warps)
    rows = Array.new(base_map.size_y) do |y|
      Array.new(base_map.size_x) do |x|
        tile = base_map[x, y]
        blocked_by_border = GameConfig::BORDER_BLOCKED && border_tile?(x, y, base_map)
        blocked_by_tile = GameConfig::IMPASSABLE_TILE_INDICES.include?(tile)
        (blocked_by_border || blocked_by_tile) ? 1 : 0
      end
    end

    warps.each do |warp|
      tx, ty = warp[:tile]
      next unless ty.between?(0, rows.size - 1) && tx.between?(0, rows[0].size - 1)

      rows[ty][tx] = 0
    end

    Map.from_rows(rows)
  end

  def border_tile?(x, y, map)
    x.zero? || y.zero? || x == map.size_x - 1 || y == map.size_y - 1
  end
end
