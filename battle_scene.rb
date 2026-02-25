require_relative "game_config"

class BattleScene
  SPELL_COST = 3

  def initialize(window, hero, enemy)
    @window = window
    @hero = hero
    @enemy = enemy

    @title_font = Gosu::Font.new(26)
    @ui_font = Gosu::Font.new(22)
    @small_font = Gosu::Font.new(18)

    @background = Gosu::Image.new(GameConfig::BG_IMAGE_PATH)

    @commands = [
      { label: "たたかう", action: :fight },
      { label: "じゅもん", action: :spell },
      { label: "けいやく", action: :pact },
      { label: "にげる", action: :run }
    ]

    reset_state
  rescue StandardError => e
    warn "戦闘シーンの初期化に失敗しました: #{e.message}"
    exit(1)
  end

  def start_encounter
    @enemy.roll!
    @selected_command = 0
    @active = true
    @guard_ratio = 0.0
    @pact_focus_bonus = 0.0
    queue_messages([@enemy.battle_intro])
  end

  def active?
    @active
  end

  def update
    return :game_map unless @active

    if @state == :finished && Gosu.milliseconds >= @finish_until
      @active = false
      return :game_map
    end

    :battle
  end

  def draw
    draw_battle_field
    draw_status_panels
    @enemy.draw
    draw_bottom_ui
  end

  def button_down(id)
    return nil unless @active

    if @state == :message
      return handle_message_input(id)
    end

    return nil unless @state == :command

    case id
    when Gosu::KB_LEFT
      move_selection(-1, 0)
    when Gosu::KB_RIGHT
      move_selection(1, 0)
    when Gosu::KB_UP
      move_selection(0, -1)
    when Gosu::KB_DOWN
      move_selection(0, 1)
    when Gosu::KB_Z, Gosu::KB_RETURN, Gosu::KB_SPACE
      perform_command(@commands[@selected_command][:action])
    when Gosu::KB_X
      perform_command(:run)
    when Gosu::MS_LEFT
      idx = command_index_from_mouse
      if idx
        @selected_command = idx
        perform_command(@commands[@selected_command][:action])
      end
    end

    :battle
  end

  private

  def reset_state
    @selected_command = 0
    @active = false
    @state = :command
    @message_queue = []
    @message_text = ""
    @next_state = :command
    @finish_until = 0
    @guard_ratio = 0.0
    @pact_focus_bonus = 0.0
  end

  def perform_command(action)
    case action
    when :fight
      player_attack_turn
    when :spell
      cast_heal
    when :pact
      attempt_pact
    when :run
      try_run
    end
  end

  def player_attack_turn
    damage = calc_damage(@hero.attack + @hero.companion_attack_bonus, @enemy.defense, variance: 3)
    @enemy.take_damage(damage)

    messages = [
      "#{@hero.name} の こうげき！",
      "#{@enemy.name} に #{damage} の ダメージ！"
    ]
    messages.concat(companion_support_messages(:fight))

    if @enemy.alive?
      queue_with_enemy_turn(messages)
    else
      messages.concat(victory_messages)
      queue_messages(messages, next_state: :battle_end)
    end
  end

  def cast_heal
    unless @hero.use_mp(SPELL_COST)
      queue_messages(["MP が たりない！"], next_state: :command)
      return
    end

    heal = 10 + rand(8)
    recovered = @hero.heal(heal)
    messages = [
      "ホイミ を となえた！",
      "#{@hero.name} は #{recovered} かいふくした。"
    ]
    messages.concat(companion_support_messages(:spell))

    if @enemy.alive?
      queue_with_enemy_turn(messages)
    else
      queue_messages(messages, next_state: :command)
    end
  end

  def attempt_pact
    if @hero.companion_full?
      queue_messages(["これいじょう けいやく できない。"], next_state: :command)
      return
    end

    if @enemy.hp_ratio > 0.45
      messages = ["#{@enemy.name} の こころが まだ ほどけない！"]
      messages.concat(companion_support_messages(:pact))
      if @enemy.alive?
        queue_with_enemy_turn(messages)
      else
        messages.concat(victory_messages)
        queue_messages(messages, next_state: :battle_end)
      end
      return
    end

    chance = pact_success_rate
    if rand < chance && @hero.form_pact(@enemy.pact_profile)
      messages = [
        "#{@hero.name} は ことだま を ひびかせた！",
        "#{@enemy.name} と けいやくが むすばれた！",
        "なかま #{ @hero.companion_count }/#{ @hero.companion_limit }"
      ]
      queue_messages(messages, next_state: :battle_end)
      return
    end

    messages = ["けいやく は しっぱいした…"]
    messages.concat(companion_support_messages(:pact))
    if @enemy.alive?
      queue_with_enemy_turn(messages)
    else
      messages.concat(victory_messages)
      queue_messages(messages, next_state: :battle_end)
    end
  end

  def try_run
    if rand < 0.7
      queue_messages(["#{@hero.name} は にげだした！"], next_state: :battle_end)
      return
    end

    messages = ["しかし まわりこまれてしまった！"]
    messages.concat(companion_support_messages(:run))
    queue_with_enemy_turn(messages)
  end

  def enemy_turn_messages
    scaled_attack = (@enemy.attack * (1.0 - @guard_ratio)).round
    damage = calc_damage([scaled_attack, 1].max, @hero.defense, variance: 2)
    guard_message = @guard_ratio.positive? ? "ストーンガードで だめーじを おさえた！" : nil
    @guard_ratio = 0.0
    @hero.take_damage(damage)
    messages = [
      "#{@enemy.name} の こうげき！",
      "#{@hero.name} は #{damage} の ダメージを うけた！"
    ]
    messages.unshift(guard_message) if guard_message
    messages
  end

  def victory_messages
    @hero.gain_gold(@enemy.gold_reward)
    level_messages = @hero.gain_exp(@enemy.exp_reward)

    [
      "#{@enemy.name} を たおした！",
      "#{@hero.name} は #{@enemy.exp_reward} EXP を えた。",
      "#{@enemy.gold_reward} G を てにいれた。"
    ] + level_messages
  end

  def pact_success_rate
    base = @enemy.pact_base_rate
    wounded_bonus = (0.45 - @enemy.hp_ratio) * 1.4
    resonance_bonus = @hero.resonance * 0.015
    [[base + wounded_bonus + resonance_bonus + @pact_focus_bonus, 0.05].max, 0.92].min
  end

  def companion_support_messages(_trigger)
    return [] unless @enemy.alive?

    ally = @hero.active_companion
    return [] unless ally
    return [] if rand >= 0.45

    case ally[:skill]
    when :mist_heal
      heal = 6 + rand(7)
      recovered = @hero.heal(heal)
      [
        "#{ally[:name]} の ミストヒール！",
        "#{@hero.name} は #{recovered} かいふくした。"
      ]
    when :flame_burst
      damage = 4 + ally[:power] + rand(6)
      @enemy.take_damage(damage)
      [
        "#{ally[:name]} の フレイムバースト！",
        "#{@enemy.name} に #{damage} の ついげき！"
      ]
    when :stone_guard
      @guard_ratio = [@guard_ratio, 0.35].max
      [
        "#{ally[:name]} の ストーンガード！",
        "つぎの てきこうげきを けいげん。"
      ]
    when :moon_chant
      @pact_focus_bonus = [@pact_focus_bonus + 0.12, 0.35].min
      [
        "#{ally[:name]} の ルナチャント！",
        "けいやくりつ が すこし あがった。"
      ]
    else
      []
    end
  end

  def queue_with_enemy_turn(messages)
    battle_messages = messages + enemy_turn_messages
    queue_messages(battle_messages, next_state: @hero.alive? ? :command : :hero_down)
  end

  def calc_damage(atk, dfs, variance: 2)
    base = atk - (dfs / 2)
    [base + rand(variance + 1), 1].max
  end

  def queue_messages(messages, next_state: :command)
    @message_queue = messages.dup
    @message_text = @message_queue.shift || ""
    @state = :message
    @next_state = next_state
  end

  def handle_message_input(id)
    return :battle unless [Gosu::KB_Z, Gosu::KB_RETURN, Gosu::KB_SPACE, Gosu::MS_LEFT].include?(id)

    if @message_queue.empty?
      on_message_end
    else
      @message_text = @message_queue.shift
    end

    :battle
  end

  def on_message_end
    case @next_state
    when :command
      @state = :command
      @message_text = "コマンドを えらんでください"
    when :hero_down
      @hero.full_recover
      @state = :finished
      @message_text = "めのまえが まっくらに なった。"
      @finish_until = Gosu.milliseconds + 1200
    when :battle_end
      @state = :finished
      @finish_until = Gosu.milliseconds + 500
    else
      @state = :command
    end
  end

  def draw_battle_field
    Gosu.draw_rect(0, 0, GameConfig::WINDOW_W, GameConfig::WINDOW_H, Gosu::Color.new(0xFFDCEFF8), 10)
    @background.draw(0, 0, 11, GameConfig::WINDOW_W.to_f / @background.width, 250.0 / @background.height, Gosu::Color.new(0xD0FFFFFF))
    Gosu.draw_rect(0, 250, GameConfig::WINDOW_W, GameConfig::WINDOW_H - 250, Gosu::Color.new(0xFFECE5D8), 11)
  end

  def draw_status_panels
    draw_panel(22, 20, 270, 92)
    draw_panel(328, 170, 290, 100)

    @ui_font.draw_text(@enemy.name, 36, 34, 30, 1.0, 1.0, Gosu::Color::BLACK)
    @ui_font.draw_text(@hero.name, 344, 184, 30, 1.0, 1.0, Gosu::Color::BLACK)

    @small_font.draw_text("HP", 36, 66, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("HP", 344, 216, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("MP", 484, 216, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("共鳴 #{@hero.resonance}", 344, 196, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("盟友 #{@hero.companion_count}/#{@hero.companion_limit}", 462, 196, 31, 1.0, 1.0, Gosu::Color::BLACK)

    draw_hp_bar(70, 68, 180, @enemy.hp, @enemy.max_hp)
    draw_hp_bar(378, 218, 90, @hero.hp, @hero.max_hp)

    @small_font.draw_text("#{@enemy.hp}/#{@enemy.max_hp}", 200, 88, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("#{@hero.hp}/#{@hero.max_hp}", 344, 238, 31, 1.0, 1.0, Gosu::Color::BLACK)
    @small_font.draw_text("#{@hero.mp}/#{@hero.max_mp}", 484, 238, 31, 1.0, 1.0, Gosu::Color::BLACK)
  end

  def draw_bottom_ui
    draw_panel(14, 288, 398, 176)
    draw_panel(414, 288, 212, 176)

    @small_font.draw_text(@message_text, 32, 312, 41, 1.0, 1.0, Gosu::Color::BLACK)

    draw_command_grid
  end

  def draw_command_grid
    2.times do |row|
      2.times do |col|
        idx = row * 2 + col
        x = 424 + col * 98
        y = 300 + row * 78
        selected = idx == @selected_command && @state == :command

        border = selected ? Gosu::Color.new(0xFF2A6FD3) : Gosu::Color.new(0xFF6D6D6D)
        base = selected ? Gosu::Color.new(0xFFE9F3FF) : Gosu::Color.new(0xFFF8F8F8)

        Gosu.draw_rect(x, y, 92, 68, border, 42)
        Gosu.draw_rect(x + 2, y + 2, 88, 64, base, 43)
        @small_font.draw_text(@commands[idx][:label], x + 18, y + 25, 44, 1.0, 1.0, Gosu::Color::BLACK)
      end
    end
  end

  def draw_panel(x, y, w, h)
    Gosu.draw_rect(x, y, w, h, Gosu::Color::BLACK, 40)
    Gosu.draw_rect(x + 2, y + 2, w - 4, h - 4, Gosu::Color.new(0xFFF9F9F9), 40)
    Gosu.draw_rect(x + 6, y + 6, w - 12, h - 12, Gosu::Color::BLACK, 40)
    Gosu.draw_rect(x + 8, y + 8, w - 16, h - 16, Gosu::Color::WHITE, 40)
  end

  def draw_hp_bar(x, y, w, hp, max_hp)
    ratio = max_hp.zero? ? 0.0 : [[hp.to_f / max_hp, 0.0].max, 1.0].min
    fill_w = (w * ratio).round

    color = if ratio > 0.5
              Gosu::Color.new(0xFF4FD460)
            elsif ratio > 0.2
              Gosu::Color.new(0xFFF2CB3D)
            else
              Gosu::Color.new(0xFFE15959)
            end

    Gosu.draw_rect(x, y, w, 14, Gosu::Color.new(0xFF2B2B2B), 32)
    Gosu.draw_rect(x + 2, y + 2, w - 4, 10, Gosu::Color.new(0xFF1B1B1B), 33)
    Gosu.draw_rect(x + 2, y + 2, [fill_w - 4, 0].max, 10, color, 34)
  end

  def move_selection(dx, dy)
    row = @selected_command / 2
    col = @selected_command % 2
    row = (row + dy) % 2
    col = (col + dx) % 2
    @selected_command = row * 2 + col
  end

  def command_index_from_mouse
    mx = @window.mouse_x
    my = @window.mouse_y
    return nil unless mx >= 424 && mx <= 614 && my >= 300 && my <= 446

    col = ((mx - 424) / 98).to_i
    row = ((my - 300) / 78).to_i
    idx = row * 2 + col
    idx.between?(0, 3) ? idx : nil
  end
end
