class Hero
  attr_reader :name, :level, :exp, :max_hp, :hp, :max_mp, :mp, :attack, :defense, :gold, :herb_count, :resonance, :companions
  SKILL_BY_SIGIL = {
    "霧" => :mist_heal,
    "炎" => :flame_burst,
    "岩" => :stone_guard,
    "月" => :moon_chant
  }.freeze

  def initialize(name: "ゆうしゃ")
    @name = name
    @level = 1
    @exp = 0
    @max_hp = 28
    @hp = @max_hp
    @max_mp = 10
    @mp = @max_mp
    @attack = 8
    @defense = 5
    @gold = 0
    @herb_count = 3
    @resonance = 1
    @companions = []
    @companion_limit = 4
  end

  def alive?
    @hp.positive?
  end

  def exp_to_next
    10 + (@level - 1) * 12
  end

  def gain_exp(amount)
    @exp += amount
    level_up_messages = []

    while @exp >= exp_to_next
      @exp -= exp_to_next
      level_up_messages.concat(level_up)
    end

    level_up_messages
  end

  def gain_gold(amount)
    @gold += amount
  end

  def companion_count
    @companions.size
  end

  def companion_limit
    @companion_limit
  end

  def companion_full?
    @companions.size >= @companion_limit
  end

  def companion_attack_bonus
    @companions.sum { |ally| ally[:power] }
  end

  def active_companion
    @companions.first
  end

  def companion_skill_name(companion)
    case companion[:skill]
    when :mist_heal
      "ミストヒール"
    when :flame_burst
      "フレイムバースト"
    when :stone_guard
      "ストーンガード"
    when :moon_chant
      "ルナチャント"
    else
      "なし"
    end
  end

  def swap_companions(index_a, index_b)
    return false unless index_a.between?(0, @companions.size - 1)
    return false unless index_b.between?(0, @companions.size - 1)

    @companions[index_a], @companions[index_b] = @companions[index_b], @companions[index_a]
    true
  end

  def form_pact(profile)
    return false if companion_full?

    @companions << build_companion(profile)
    @resonance += 1
    true
  end

  def to_save_data
    {
      "name" => @name,
      "level" => @level,
      "exp" => @exp,
      "max_hp" => @max_hp,
      "hp" => @hp,
      "max_mp" => @max_mp,
      "mp" => @mp,
      "attack" => @attack,
      "defense" => @defense,
      "gold" => @gold,
      "herb_count" => @herb_count,
      "resonance" => @resonance,
      "companions" => @companions.map do |ally|
        {
          "name" => ally[:name],
          "sigil" => ally[:sigil],
          "power" => ally[:power],
          "skill" => ally[:skill].to_s
        }
      end
    }
  end

  def load_from_save_data(data)
    @name = data["name"] || @name
    @level = integer_or_default(data["level"], @level)
    @exp = integer_or_default(data["exp"], @exp)
    @max_hp = [integer_or_default(data["max_hp"], @max_hp), 1].max
    @hp = [[integer_or_default(data["hp"], @hp), 0].max, @max_hp].min
    @max_mp = [integer_or_default(data["max_mp"], @max_mp), 0].max
    @mp = [[integer_or_default(data["mp"], @mp), 0].max, @max_mp].min
    @attack = [integer_or_default(data["attack"], @attack), 1].max
    @defense = [integer_or_default(data["defense"], @defense), 0].max
    @gold = [integer_or_default(data["gold"], @gold), 0].max
    @herb_count = [integer_or_default(data["herb_count"], @herb_count), 0].max
    @resonance = [integer_or_default(data["resonance"], @resonance), 1].max

    raw_companions = data["companions"]
    @companions = if raw_companions.is_a?(Array)
                    raw_companions.first(@companion_limit).map { |comp| build_companion(comp) }
                  else
                    []
                  end
  end

  def take_damage(amount)
    damage = [amount, 0].max
    @hp = [@hp - damage, 0].max
    damage
  end

  def heal(amount)
    recovered = [[amount, 0].max, @max_hp - @hp].min
    @hp += recovered
    recovered
  end

  def use_mp(cost)
    return false if @mp < cost

    @mp -= cost
    true
  end

  def use_herb
    return false if @herb_count <= 0

    @herb_count -= 1
    true
  end

  def full_recover
    @hp = @max_hp
    @mp = @max_mp
  end

  private

  def integer_or_default(value, fallback)
    Integer(value, 10)
  rescue StandardError
    fallback
  end

  def build_companion(profile)
    sigil = profile[:sigil] || profile["sigil"] || "無"
    skill_name = profile[:skill] || profile["skill"]
    skill = if skill_name
              skill_name.to_sym
            else
              SKILL_BY_SIGIL[sigil] || :none
            end

    {
      name: profile[:name] || profile["name"] || "ななし",
      sigil: sigil,
      power: integer_or_default(profile[:power] || profile["power"], 1),
      skill: skill
    }
  end

  def level_up
    @level += 1

    hp_gain = 4 + rand(3)
    mp_gain = 2 + rand(2)
    atk_gain = 2 + rand(2)
    def_gain = 1 + rand(2)

    @max_hp += hp_gain
    @max_mp += mp_gain
    @attack += atk_gain
    @defense += def_gain
    @resonance += 1 if (@level % 3).zero?
    @hp = @max_hp
    @mp = @max_mp

    [
      "#{@name}は レベル#{@level}に あがった！",
      "HPが #{hp_gain} あがった。 MPが #{mp_gain} あがった。",
      "こうげきりょくが #{atk_gain} あがった。 しゅびりょくが #{def_gain} あがった。"
    ]
  end
end
