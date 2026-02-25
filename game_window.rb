require_relative "game_config"
require_relative "map"
require_relative "enemy"
require_relative "hero"
require_relative "player"
require_relative "battle_scene"
require_relative "world_map_manager"
require_relative "save_data"
require_relative "npc"
require_relative "story_manager"

class GameWindow < Gosu::Window
  def initialize
    super(GameConfig::WINDOW_W, GameConfig::WINDOW_H, false)
    self.caption = "DRQ sample"

    @hud_font = Gosu::Font.new(18)

    @map_tiles = load_all_map_tiles
    raise "マップチップ画像が読み込めませんでした" if @map_tiles.empty?
    @npc_images = load_npc_images

    @hero = Hero.new(name: "ゆうしゃ")
    @player = Player.new(0, 0, GameConfig::PLAYER_IMAGE_PATH)
    @enemy = Enemy.new(GameConfig::ENEMY_IMAGE_PATH)

    @world_map = WorldMapManager.new(GameConfig::WORLD_MAPS)
    load_map(GameConfig::START_MAP)

    @battle_scene = BattleScene.new(self, @hero, @enemy)
    @story = StoryManager.new
    @scene = :game_map
    @menu_cursor = 0
    @menu_swap_from = nil
    @notice_text = nil
    @notice_until = 0
    @map_dialog_queue = []
    @map_dialog_text = nil
  rescue Errno::ENOENT => e
    warn "データファイルが見つかりません: #{e.message}"
    exit(1)
  rescue StandardError => e
    warn "初期化に失敗しました: #{e.message}"
    exit(1)
  end

  def update
    @scene = case @scene
             when :game_map
               update_game_map
             when :battle
               @battle_scene.update
             else
               :companion_menu
             end
  end

  def draw
    if @scene == :game_map
      draw_game_map
    elsif @scene == :battle
      @battle_scene.draw
    else
      draw_game_map
      draw_companion_menu
    end
  end

  def button_down(id)
    if id == Gosu::KB_ESCAPE
      if @scene == :companion_menu
        @scene = :game_map
        return
      end
      close
      return
    end

    case @scene
    when :battle
      next_scene = @battle_scene.button_down(id)
      @scene = next_scene if next_scene
    when :game_map
      handle_map_button(id)
    when :companion_menu
      handle_companion_menu_input(id)
    end
  end

  def needs_cursor?
    @scene == :battle || @scene == :companion_menu
  end

  private

  def update_game_map
    if notice_active? && Gosu.milliseconds >= @notice_until
      @notice_text = nil
    end
    return :game_map if map_dialog_active?

    prev_x = @player.mx
    prev_y = @player.my

    moved = @player.update(input_x, input_y, @map_base, @collision_map)

    target_x = @player.mx - GameConfig::VIEW_W / 2
    target_y = @player.my - GameConfig::VIEW_H / 2

    max_x = [@map_base.size_x * GameConfig::TILE_SIZE - GameConfig::VIEW_W, 0].max
    max_y = [@map_base.size_y * GameConfig::TILE_SIZE - GameConfig::VIEW_H, 0].max
    target_x = [[target_x, 0].max, max_x].min
    target_y = [[target_y, 0].max, max_y].min

    @camera_x += (target_x - @camera_x) * GameConfig::CAMERA_LERP
    @camera_y += (target_y - @camera_y) * GameConfig::CAMERA_LERP
    @map_x = @camera_x.round
    @map_y = @camera_y.round

    actually_moved = moved || @player.mx != prev_x || @player.my != prev_y

    handle_map_transition if actually_moved

    if GameConfig::RANDOM_ENCOUNTER_ENABLED && actually_moved && rand(100) < GameConfig::RANDOM_ENCOUNTER_RATE
      @battle_scene.start_encounter
      return :battle
    end

    :game_map
  end

  def draw_game_map
    draw_map_chrome

    Gosu.clip_to(GameConfig::VIEW_X, GameConfig::VIEW_Y, GameConfig::VIEW_W, GameConfig::VIEW_H) do
      @map_base.draw(@map_tiles, @map_x, @map_y, GameConfig::VIEW_X, GameConfig::VIEW_Y, GameConfig::VIEW_W, GameConfig::VIEW_H, 5)

      player_screen_x = GameConfig::VIEW_X + @player.mx - @map_x
      player_screen_y = GameConfig::VIEW_Y + @player.my - @map_y
      @player.draw(player_screen_x, player_screen_y, 6)
      draw_npcs

      @map_sub.draw(@map_tiles, @map_x, @map_y, GameConfig::VIEW_X, GameConfig::VIEW_Y, GameConfig::VIEW_W, GameConfig::VIEW_H, 7)
      draw_warp_marker
      draw_core_marker
    end

    draw_hud
    draw_map_dialog if map_dialog_active?
  end

  def draw_map_chrome
    Gosu.draw_rect(0, 0, GameConfig::WINDOW_W, GameConfig::WINDOW_H, Gosu::Color.new(0xFF202733), 0)
    Gosu.draw_rect(GameConfig::VIEW_X - 6, GameConfig::VIEW_Y - 6, GameConfig::VIEW_W + 12, GameConfig::VIEW_H + 12, Gosu::Color.new(0xFF11161F), 1)
    Gosu.draw_rect(GameConfig::VIEW_X, GameConfig::VIEW_Y, GameConfig::VIEW_W, GameConfig::VIEW_H, Gosu::Color.new(0xFF0A0D12), 2)
    Gosu.draw_rect(GameConfig::VIEW_X - 2, GameConfig::VIEW_Y - 2, GameConfig::VIEW_W + 4, 2, Gosu::Color.new(0xFFB9D1EA), 3)
    Gosu.draw_rect(GameConfig::VIEW_X - 2, GameConfig::VIEW_Y + GameConfig::VIEW_H, GameConfig::VIEW_W + 4, 2, Gosu::Color.new(0xFF5F748B), 3)
    Gosu.draw_rect(GameConfig::VIEW_X - 2, GameConfig::VIEW_Y, 2, GameConfig::VIEW_H, Gosu::Color.new(0xFFB9D1EA), 3)
    Gosu.draw_rect(GameConfig::VIEW_X + GameConfig::VIEW_W, GameConfig::VIEW_Y, 2, GameConfig::VIEW_H, Gosu::Color.new(0xFF5F748B), 3)
  end

  def draw_hud
    x = 8
    y = 8
    w = 240
    h = 74

    Gosu.draw_rect(x, y, w, h, Gosu::Color::BLACK, 20)
    Gosu.draw_rect(x + 2, y + 2, w - 4, h - 4, Gosu::Color::WHITE, 20)

    @hud_font.draw_text("Lv #{@hero.level}  #{@hero.name}", x + 10, y + 8, 21, 1.0, 1.0, Gosu::Color::BLACK)
    @hud_font.draw_text("HP #{@hero.hp}/#{@hero.max_hp}", x + 10, y + 30, 21, 1.0, 1.0, Gosu::Color::BLACK)
    @hud_font.draw_text("MP #{@hero.mp}/#{@hero.max_mp}  G #{@hero.gold}", x + 110, y + 30, 21, 1.0, 1.0, Gosu::Color::BLACK)
    @hud_font.draw_text("共鳴 #{@hero.resonance}  盟友 #{@hero.companion_count}/#{@hero.companion_limit}", x + 10, y + 52, 21, 1.0, 1.0, Gosu::Color::BLACK)

    @hud_font.draw_text("C:盟友メニュー  Z:調べる/会話  F5:セーブ  F9:ロード", 262, 10, 21, 1.0, 1.0, Gosu::Color::WHITE)
    @hud_font.draw_text("章 #{@story.chapter}: #{@story.objective_text}", 262, 58, 21, 1.0, 1.0, Gosu::Color::WHITE)
    @hud_font.draw_text(@notice_text, 262, 36, 21, 1.0, 1.0, Gosu::Color.new(0xFFFFE089)) if notice_active?
  end

  def draw_companion_menu
    panel_x = 60
    panel_y = 58
    panel_w = GameConfig::WINDOW_W - 120
    panel_h = GameConfig::WINDOW_H - 116

    Gosu.draw_rect(panel_x, panel_y, panel_w, panel_h, Gosu::Color.new(0xE01A1E28), 80)
    Gosu.draw_rect(panel_x + 4, panel_y + 4, panel_w - 8, panel_h - 8, Gosu::Color.new(0xF7F8FAFF), 81)
    @hud_font.draw_text("盟友メニュー", panel_x + 16, panel_y + 12, 82, 1.0, 1.0, Gosu::Color::BLACK)
    @hud_font.draw_text("↑↓:選択  Z:選択/入替  X:戻る  S:保存  L:読込", panel_x + 16, panel_y + 36, 82, 1.0, 1.0, Gosu::Color::BLACK)

    companions = @hero.companions
    if companions.empty?
      @hud_font.draw_text("まだ盟友がいません。戦闘で「けいやく」を試してください。", panel_x + 16, panel_y + 84, 82, 1.0, 1.0, Gosu::Color::BLACK)
      return
    end

    companions.each_with_index do |ally, idx|
      row_y = panel_y + 72 + idx * 54
      selected = idx == @menu_cursor
      swapping = idx == @menu_swap_from
      bg = if swapping
             Gosu::Color.new(0xFFFFE7A3)
           elsif selected
             Gosu::Color.new(0xFFE0ECFF)
           else
             Gosu::Color.new(0xFFF8F8F8)
           end
      Gosu.draw_rect(panel_x + 14, row_y, panel_w - 28, 44, bg, 82)
      role = idx.zero? ? "先頭" : "控え"
      skill = @hero.companion_skill_name(ally)
      @hud_font.draw_text("#{idx + 1}. #{ally[:name]} [#{ally[:sigil]}] 役割:#{role}", panel_x + 24, row_y + 10, 83, 1.0, 1.0, Gosu::Color::BLACK)
      @hud_font.draw_text("力 #{ally[:power]}  特技 #{skill}", panel_x + 292, row_y + 10, 83, 1.0, 1.0, Gosu::Color::BLACK)
    end
  end

  def input_x
    left = button_down?(Gosu::KB_LEFT) ? -1 : 0
    right = button_down?(Gosu::KB_RIGHT) ? 1 : 0
    left + right
  end

  def input_y
    up = button_down?(Gosu::KB_UP) ? -1 : 0
    down = button_down?(Gosu::KB_DOWN) ? 1 : 0
    up + down
  end

  def load_all_map_tiles
    path = GameConfig::MAP_TILESET_PATH
    tiles = Gosu::Image.load_tiles(path, GameConfig::TILE_SIZE, GameConfig::TILE_SIZE, tileable: false)
    raise "マップチップ画像のタイル数が0です: #{path}" if tiles.empty?

    tiles
  rescue StandardError => e
    raise "マップチップ読み込み失敗: #{File.basename(path)} (#{e.message})"
  end

  def load_map(map_key, spawn_tile = nil)
    @world_map.load!(map_key, spawn_tile)
    @map_base = @world_map.base_map
    @map_sub = @world_map.sub_map
    @collision_map = @world_map.collision_map
    @map_npcs = build_map_npcs(@world_map.npcs)
    @map_dialog_queue = []
    @map_dialog_text = nil

    spawn_x, spawn_y = @world_map.spawn_tile
    @player.warp_to(spawn_x, spawn_y)
    reset_camera
  end

  def load_npc_images
    images = {}
    Dir.glob(File.join(GameConfig::NPC_IMAGE_DIR, "*.png")).sort.each do |path|
      images[File.basename(path)] = Gosu::Image.new(path)
    end
    images
  end

  def build_map_npcs(npc_entries)
    npc_entries.filter_map do |entry|
      image = @npc_images[entry[:sprite]]
      next nil unless image

      Npc.new(
        name: entry[:name],
        tile_x: entry[:tile][0],
        tile_y: entry[:tile][1],
        image: image,
        tile_size: GameConfig::TILE_SIZE
      )
    end
  end

  def draw_npcs
    return if @map_npcs.nil? || @map_npcs.empty?

    @map_npcs.each do |npc|
      npc.draw(@map_x, @map_y, GameConfig::VIEW_X, GameConfig::VIEW_Y, 6)
    end
  end

  def handle_map_transition
    player_tile = [@player.mx / GameConfig::TILE_SIZE, @player.my / GameConfig::TILE_SIZE]
    transition = @world_map.transition_for(*player_tile)
    return unless transition

    load_map(transition[:to], transition[:spawn])
  end

  def reset_camera
    @map_x = @player.mx - GameConfig::VIEW_W / 2
    @map_y = @player.my - GameConfig::VIEW_H / 2

    max_x = [@map_base.size_x * GameConfig::TILE_SIZE - GameConfig::VIEW_W, 0].max
    max_y = [@map_base.size_y * GameConfig::TILE_SIZE - GameConfig::VIEW_H, 0].max
    @map_x = [[@map_x, 0].max, max_x].min
    @map_y = [[@map_y, 0].max, max_y].min
    @camera_x = @map_x.to_f
    @camera_y = @map_y.to_f
  end

  def draw_warp_marker
    @world_map.warps.each do |warp|
      tile_x, tile_y = warp[:tile]
      x = GameConfig::VIEW_X + tile_x * GameConfig::TILE_SIZE - @map_x
      y = GameConfig::VIEW_Y + tile_y * GameConfig::TILE_SIZE - @map_y

      Gosu.draw_rect(x, y, GameConfig::TILE_SIZE, GameConfig::TILE_SIZE, Gosu::Color.new(0x66FFD14A), 8)
      Gosu.draw_rect(x + 2, y + 2, GameConfig::TILE_SIZE - 4, GameConfig::TILE_SIZE - 4, Gosu::Color.new(0x55334A7A), 9)
    end
  end

  def draw_core_marker
    map_key = @world_map.current_key
    core = GameConfig::CORE_TILES[map_key]
    return if core.nil?
    return if @story.core_restored?(map_key)

    tile_x, tile_y = core
    x = GameConfig::VIEW_X + tile_x * GameConfig::TILE_SIZE - @map_x
    y = GameConfig::VIEW_Y + tile_y * GameConfig::TILE_SIZE - @map_y

    pulse = ((Math.sin(Gosu.milliseconds / 180.0) + 1.0) * 0.5 * 90).to_i + 110
    Gosu.draw_rect(x, y, GameConfig::TILE_SIZE, GameConfig::TILE_SIZE, Gosu::Color.rgba(80, 210, 255, pulse), 10)
    Gosu.draw_rect(x + 6, y + 6, GameConfig::TILE_SIZE - 12, GameConfig::TILE_SIZE - 12, Gosu::Color.rgba(20, 70, 140, pulse), 11)
  end

  def draw_map_dialog
    panel_x = 22
    panel_y = GameConfig::WINDOW_H - 124
    panel_w = GameConfig::WINDOW_W - 44
    panel_h = 102

    Gosu.draw_rect(panel_x, panel_y, panel_w, panel_h, Gosu::Color::BLACK, 120)
    Gosu.draw_rect(panel_x + 3, panel_y + 3, panel_w - 6, panel_h - 6, Gosu::Color::WHITE, 121)
    Gosu.draw_rect(panel_x + 7, panel_y + 7, panel_w - 14, panel_h - 14, Gosu::Color.new(0xFF101720), 122)
    @hud_font.draw_text(@map_dialog_text.to_s, panel_x + 18, panel_y + 22, 123, 1.0, 1.0, Gosu::Color::WHITE)
    @hud_font.draw_text("Z/Enter: 次へ", panel_x + panel_w - 150, panel_y + 72, 123, 1.0, 1.0, Gosu::Color.new(0xFFB8D6FF))
  end

  def handle_map_button(id)
    if [Gosu::KB_Z, Gosu::KB_RETURN, Gosu::KB_SPACE].include?(id)
      if map_dialog_active?
        advance_map_dialog
      else
        start_world_interaction
      end
      return
    end

    case id
    when Gosu::KB_C
      return if map_dialog_active?
      @scene = :companion_menu
      @menu_cursor = 0
      @menu_swap_from = nil
    when Gosu::KB_F5
      save_progress
    when Gosu::KB_F9
      load_progress
    end
  end

  def handle_companion_menu_input(id)
    max_index = [@hero.companions.size - 1, 0].max

    case id
    when Gosu::KB_UP
      @menu_cursor = [@menu_cursor - 1, 0].max
    when Gosu::KB_DOWN
      @menu_cursor = [@menu_cursor + 1, max_index].min
    when Gosu::KB_Z, Gosu::KB_RETURN, Gosu::KB_SPACE
      if @hero.companions.empty?
        show_notice("盟友がいません。")
      elsif @menu_swap_from.nil?
        @menu_swap_from = @menu_cursor
      else
        swapped = @hero.swap_companions(@menu_swap_from, @menu_cursor)
        show_notice(swapped ? "並び順を変更しました。" : "並び替えに失敗しました。")
        @menu_swap_from = nil
      end
    when Gosu::KB_X
      if @menu_swap_from
        @menu_swap_from = nil
      else
        @scene = :game_map
      end
    when Gosu::KB_S
      save_progress
    when Gosu::KB_L
      load_progress
      @scene = :companion_menu
    end
  end

  def save_progress
    tile_x = @player.mx / GameConfig::TILE_SIZE
    tile_y = @player.my / GameConfig::TILE_SIZE
    SaveData.save(
      hero: @hero,
      map_key: @world_map.current_key,
      tile_x: tile_x,
      tile_y: tile_y,
      story: @story.to_save_data
    )
    show_notice("セーブしました。")
  rescue StandardError => e
    show_notice("セーブ失敗: #{e.message}")
  end

  def load_progress
    data = SaveData.load
    unless data
      show_notice("セーブデータがありません。")
      return false
    end

    @hero.load_from_save_data(data["hero"] || {})
    @story.load_from_save_data(data["story"] || {})
    map_key = (data["map_key"] || GameConfig::START_MAP.to_s).to_sym
    tile_x = integer_or_default(data["tile_x"], 2)
    tile_y = integer_or_default(data["tile_y"], GameConfig::TEST_MAP_HEIGHT / 2)
    load_map(map_key, [tile_x, tile_y])
    show_notice("ロードしました。")
    true
  rescue StandardError => e
    show_notice("ロード失敗: #{e.message}")
    false
  end

  def integer_or_default(value, fallback)
    Integer(value, 10)
  rescue StandardError
    fallback
  end

  def show_notice(text)
    @notice_text = text
    @notice_until = Gosu.milliseconds + 1800
  end

  def notice_active?
    !@notice_text.nil?
  end

  def map_dialog_active?
    !@map_dialog_text.nil?
  end

  def start_map_dialog(lines)
    return if lines.nil? || lines.empty?

    @map_dialog_queue = lines.dup
    @map_dialog_text = @map_dialog_queue.shift
  end

  def advance_map_dialog
    if @map_dialog_queue.empty?
      @map_dialog_text = nil
    else
      @map_dialog_text = @map_dialog_queue.shift
    end
  end

  def start_world_interaction
    player_tile_x = @player.mx / GameConfig::TILE_SIZE
    player_tile_y = @player.my / GameConfig::TILE_SIZE

    npc = nearby_npc(player_tile_x, player_tile_y)
    if npc
      start_map_dialog(@story.npc_dialog(@world_map.current_key, npc.name))
      return
    end

    core = GameConfig::CORE_TILES[@world_map.current_key]
    if core && tile_near?(player_tile_x, player_tile_y, core[0], core[1], range: 1)
      start_map_dialog(@story.interact_core(@world_map.current_key, @hero))
      return
    end

    show_notice("調べる対象がありません。")
  end

  def nearby_npc(tile_x, tile_y)
    return nil if @map_npcs.nil?

    @map_npcs.find { |npc| tile_near?(tile_x, tile_y, npc.tile_x, npc.tile_y, range: 1) }
  end

  def tile_near?(x1, y1, x2, y2, range:)
    (x1 - x2).abs + (y1 - y2).abs <= range
  end
end
