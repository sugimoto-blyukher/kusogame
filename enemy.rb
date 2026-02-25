require_relative "game_config"

class Enemy
  attr_reader :name, :hp, :max_hp, :attack, :defense, :exp_reward, :gold_reward, :sigil, :temper, :pact_base_rate

  ENEMIES = [
    {
      name: "ミストリング",
      sprite: "mistling.png",
      sigil: "霧",
      temper: "おだやか",
      max_hp: 12,
      attack: 4,
      defense: 2,
      exp: 4,
      gold: 3,
      pact_rate: 0.42,
      ally_power: 1
    },
    {
      name: "ブレイズコア",
      sprite: "blazecore.png",
      sigil: "炎",
      temper: "こうせんてき",
      max_hp: 16,
      attack: 7,
      defense: 2,
      exp: 6,
      gold: 5,
      pact_rate: 0.32,
      ally_power: 2
    },
    {
      name: "グラベルノート",
      sprite: "gravelnote.png",
      sigil: "岩",
      temper: "しんちょう",
      max_hp: 20,
      attack: 6,
      defense: 4,
      exp: 8,
      gold: 6,
      pact_rate: 0.26,
      ally_power: 2
    },
    {
      name: "ルナフェザー",
      sprite: "lunafeather.png",
      sigil: "月",
      temper: "きまぐれ",
      max_hp: 14,
      attack: 8,
      defense: 3,
      exp: 9,
      gold: 8,
      pact_rate: 0.2,
      ally_power: 3
    }
  ].freeze

  def initialize(image_path)
    @fallback_image = Gosu::Image.new(image_path)
    @images = load_monster_images
    @image = @fallback_image
    @x = 340
    @y = 96
    roll!
  rescue StandardError
    warn "敵画像 '#{image_path}' が見つかりません。"
    exit(1)
  end

  def roll!
    base = ENEMIES.sample
    @name = base[:name]
    @sigil = base[:sigil]
    @temper = base[:temper]
    @max_hp = base[:max_hp]
    @hp = @max_hp
    @attack = base[:attack]
    @defense = base[:defense]
    @exp_reward = base[:exp]
    @gold_reward = base[:gold]
    @pact_base_rate = base[:pact_rate]
    @ally_power = base[:ally_power]
    sprite = base[:sprite]
    @image = @images[sprite] || @fallback_image
  end

  def alive?
    @hp.positive?
  end

  def take_damage(amount)
    damage = [amount, 0].max
    @hp = [@hp - damage, 0].max
    damage
  end

  def hp_ratio
    return 0.0 if @max_hp.zero?

    @hp.to_f / @max_hp
  end

  def pact_profile
    { name: @name, sigil: @sigil, power: @ally_power }
  end

  def battle_intro
    "#{@name}（#{@sigil}の印・#{@temper}）が あらわれた！"
  end

  def draw(z = 40)
    draw_x = @x + (96 - @image.width) / 2
    draw_y = @y + (96 - @image.height)
    @image.draw(draw_x, draw_y, z)
  end

  private

  def load_monster_images
    images = {}
    ENEMIES.each do |entry|
      sprite = entry[:sprite]
      next if sprite.nil? || images.key?(sprite)

      path = File.join(GameConfig::MONSTER_IMAGE_DIR, sprite)
      images[sprite] = Gosu::Image.new(path)
    rescue StandardError => e
      warn "モンスター画像読み込み失敗: #{sprite} (#{e.message})"
    end
    images
  end
end
