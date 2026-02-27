module GameConfig
  BASE_DIR = __dir__
  MAP_TILESET_PATH = File.join(BASE_DIR, "image", "custom", "world_tiles.png")
  NPC_IMAGE_DIR = File.join(BASE_DIR, "image", "custom", "npc")
  MONSTER_IMAGE_DIR = File.join(BASE_DIR, "image", "custom", "monsters")
  BG_IMAGE_PATH = File.join(BASE_DIR, "image", "BG00a1_80.jpg")
  ENEMY_IMAGE_PATH = File.join(BASE_DIR, "image", "ruby.png")
  PLAYER_IMAGE_PATH = File.join(BASE_DIR, "image", "ruby.png")

  TILE_SIZE = 32
  WINDOW_W = 640
  WINDOW_H = 480
  VIEW_X = 32
  VIEW_Y = 32
  VIEW_W = WINDOW_W - 64
  VIEW_H = WINDOW_H - 64
  CAMERA_LERP = 0.25
  RANDOM_ENCOUNTER_ENABLED = false
  RANDOM_ENCOUNTER_RATE = 6
  TEST_MAP_WIDTH = 36
  TEST_MAP_HEIGHT = 24
  BORDER_BLOCKED = true
  IMPASSABLE_TILE_INDICES = [5, 6, 7, 8, 9, 10, 14, 16, 18, 22, 24, 28, 29, 31].freeze

  NPC_SPAWNS = {
    field_01: [
      { name: "ミナト", tile: [7, 8], sprite: "npc_01.png" },
      { name: "リコ", tile: [9, 8], sprite: "npc_02.png" },
      { name: "ドン", tile: [11, 8], sprite: "npc_03.png" },
      { name: "サラ", tile: [7, 10], sprite: "npc_04.png" },
      { name: "レン", tile: [9, 10], sprite: "npc_05.png" },
      { name: "ハル", tile: [11, 10], sprite: "npc_06.png" },
      { name: "ユイ", tile: [6, 12], sprite: "npc_07.png" },
      { name: "カイ", tile: [8, 12], sprite: "npc_08.png" },
      { name: "ノア", tile: [10, 12], sprite: "npc_09.png" },
      { name: "メイ", tile: [12, 12], sprite: "npc_10.png" }
    ],
    field_02: [{ name: "ギン", tile: [24, 8], sprite: "npc_11.png" }],
    field_03: [{ name: "アオ", tile: [6, 17], sprite: "npc_12.png" }],
    field_04: [{ name: "クロ", tile: [23, 15], sprite: "npc_13.png" }],
    field_05: [{ name: "ルナ", tile: [15, 9], sprite: "npc_14.png" }],
    field_06: [{ name: "トワ", tile: [10, 11], sprite: "npc_15.png" }]
  }.freeze

  CORE_TILES = {
    field_01: [9, 7],
    field_02: [26, 7],
    field_03: [8, 16],
    field_04: [25, 16],
    field_05: [17, 9],
    field_06: [12, 12],
    field_07: [28, 12],
    field_08: [10, 9],
    field_09: [26, 9],
    field_10: [18, 16]
  }.freeze

  FIELD_MAP_IDS = (1..10).map { |n| format("field_%02d", n).to_sym }.freeze
  TOWN_MAP_IDS = (1..20).map { |n| format("town_%02d", n).to_sym }.freeze
  DUNGEON_MAP_IDS = (1..10).map { |n| format("dungeon_%02d", n).to_sym }.freeze
  WORLD_MAP_IDS = FIELD_MAP_IDS
  START_MAP = :field_01

  def self.build_town_rows(index)
    rows = Array.new(TEST_MAP_HEIGHT) { Array.new(TEST_MAP_WIDTH, 0) }
    center_x = TEST_MAP_WIDTH / 2
    center_y = TEST_MAP_HEIGHT / 2
    house_x = 6 + (index % 4)
    pond_x = TEST_MAP_WIDTH - 10 - (index % 3)

    (2...(TEST_MAP_WIDTH - 2)).each do |x|
      rows[3][x] = 11
      rows[TEST_MAP_HEIGHT - 4][x] = 11
    end
    (3...(TEST_MAP_HEIGHT - 3)).each do |y|
      rows[y][center_x] = 11
    end

    (house_x...(house_x + 7)).each do |x|
      (6..10).each do |y|
        rows[y][x] = 9
      end
    end
    rows[10][house_x + 3] = 0

    (pond_x...(pond_x + 4)).each do |x|
      (8..11).each do |y|
        rows[y][x] = 6
      end
    end

    rows[center_y][1] = 0
    rows[center_y][2] = 11

    rows
  end

  def self.build_dungeon_rows(index)
    rows = Array.new(TEST_MAP_HEIGHT) { Array.new(TEST_MAP_WIDTH, 8) }
    center_y = TEST_MAP_HEIGHT / 2
    center_x = TEST_MAP_WIDTH / 2

    (1...(TEST_MAP_WIDTH - 1)).each do |x|
      rows[center_y][x] = 0
    end
    (2...(TEST_MAP_HEIGHT - 2)).each do |y|
      rows[y][center_x] = 0
    end

    [8, 14, 22, 28].each do |x|
      offset = (index + x) % 5
      (4...(TEST_MAP_HEIGHT - 4)).each do |y|
        rows[y][x] = 0 if ((y + offset) % 3).zero?
      end
    end

    (3...(TEST_MAP_WIDTH - 3)).step(6) do |x|
      rows[5][x] = 0
      rows[TEST_MAP_HEIGHT - 6][x + 2] = 0 if x + 2 < TEST_MAP_WIDTH - 2
    end

    rows[center_y][1] = 0
    rows[center_y][2] = 0

    rows
  end

  def self.town_npcs(town_index)
    sprite_a = format("npc_%02d.png", (town_index % 15) + 1)
    sprite_b = format("npc_%02d.png", ((town_index + 6) % 15) + 1)
    [
      { name: "町人#{town_index + 1}A", tile: [12, 8], sprite: sprite_a },
      { name: "町人#{town_index + 1}B", tile: [23, 14], sprite: sprite_b }
    ]
  end

  WORLD_MAPS = begin
    maps = {}
    mid_y = TEST_MAP_HEIGHT / 2
    top_x = TEST_MAP_WIDTH / 2

    field_count = FIELD_MAP_IDS.length

    FIELD_MAP_IDS.each_with_index do |field_id, index|
      prev_map = FIELD_MAP_IDS[(index - 1) % FIELD_MAP_IDS.length]
      next_map = FIELD_MAP_IDS[(index + 1) % FIELD_MAP_IDS.length]
      opposite_map = FIELD_MAP_IDS[(index + 5) % FIELD_MAP_IDS.length]
      town_id_a = TOWN_MAP_IDS[index]
      town_id_b = TOWN_MAP_IDS[index + field_count]
      dungeon_id = DUNGEON_MAP_IDS[index]

      maps[field_id] = {
        layer: :field,
        parent: nil,
        file: File.join(BASE_DIR, "mdat", format("world_%02d.dat", index + 1)),
        spawn_tile: [2, mid_y],
        npcs: NPC_SPAWNS.fetch(field_id, []),
        warps: [
          { tile: [1, mid_y], to: prev_map, spawn: [TEST_MAP_WIDTH - 3, mid_y] },
          { tile: [TEST_MAP_WIDTH - 2, mid_y], to: next_map, spawn: [2, mid_y] },
          { tile: [top_x, 1], to: opposite_map, spawn: [top_x, TEST_MAP_HEIGHT - 3] },
          { tile: [top_x - 4, 3], to: town_id_a, spawn: [2, mid_y] },
          { tile: [top_x - 2, 3], to: town_id_b, spawn: [2, mid_y] },
          { tile: [top_x + 2, 3], to: dungeon_id, spawn: [2, mid_y] }
        ]
      }

      maps[town_id_a] = {
        layer: :town,
        parent: field_id,
        file: File.join(BASE_DIR, "mdat", format("town_%02d.dat", index + 1)),
        spawn_tile: [2, mid_y],
        npcs: town_npcs(index),
        warps: [
          { tile: [1, mid_y], to: field_id, spawn: [top_x - 4, 4] }
        ]
      }

      maps[town_id_b] = {
        layer: :town,
        parent: field_id,
        file: File.join(BASE_DIR, "mdat", format("town_%02d.dat", index + field_count + 1)),
        spawn_tile: [2, mid_y],
        npcs: town_npcs(index + field_count),
        warps: [
          { tile: [1, mid_y], to: field_id, spawn: [top_x - 2, 4] }
        ]
      }

      maps[dungeon_id] = {
        layer: :dungeon,
        parent: field_id,
        source: build_dungeon_rows(index),
        spawn_tile: [2, mid_y],
        npcs: [],
        warps: [
          { tile: [1, mid_y], to: field_id, spawn: [top_x + 2, 4] }
        ]
      }
    end

    maps
  end.freeze
end
