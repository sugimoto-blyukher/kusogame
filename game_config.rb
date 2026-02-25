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
  IMPASSABLE_TILE_INDICES = [5, 6, 7, 8, 9, 10, 14].freeze

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

  WORLD_MAP_IDS = (1..10).map { |n| format("field_%02d", n).to_sym }.freeze
  START_MAP = :field_01

  WORLD_MAPS = begin
    maps = {}
    mid_y = TEST_MAP_HEIGHT / 2
    top_x = TEST_MAP_WIDTH / 2

    WORLD_MAP_IDS.each_with_index do |map_id, index|
      prev_map = WORLD_MAP_IDS[(index - 1) % WORLD_MAP_IDS.length]
      next_map = WORLD_MAP_IDS[(index + 1) % WORLD_MAP_IDS.length]
      opposite_map = WORLD_MAP_IDS[(index + 5) % WORLD_MAP_IDS.length]

      maps[map_id] = {
        file: File.join(BASE_DIR, "mdat", format("world_%02d.dat", index + 1)),
        spawn_tile: [2, mid_y],
        npcs: NPC_SPAWNS.fetch(map_id, []),
        warps: [
          { tile: [1, mid_y], to: prev_map, spawn: [TEST_MAP_WIDTH - 3, mid_y] },
          { tile: [TEST_MAP_WIDTH - 2, mid_y], to: next_map, spawn: [2, mid_y] },
          { tile: [top_x, 1], to: opposite_map, spawn: [top_x, TEST_MAP_HEIGHT - 3] }
        ]
      }
    end

    maps
  end.freeze
end
