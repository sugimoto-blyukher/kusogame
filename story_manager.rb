class StoryManager
  MAP_TITLES = {
    field_01: "風車の町ミルクレスト",
    field_02: "樹冠都市グリーンベル",
    field_03: "湖鏡の港レイクハース",
    field_04: "断崖砦クラグフォート",
    field_05: "砂都サンヴェイル",
    field_06: "灰谷グレイリッジ",
    field_07: "潮鳴村コーラルパス",
    field_08: "霧沼ノクスフェン",
    field_09: "高天台スカイルーム",
    field_10: "環王都アステリア"
  }.freeze

  CHAPTER_ORDER = MAP_TITLES.keys.freeze

  def initialize
    @story_chapter = 1
    @core_restored = {}
    CHAPTER_ORDER.each { |key| @core_restored[key] = false }
    @future_revealed = false
    @ending_type = nil
  end

  def chapter
    @story_chapter
  end

  def objective_text
    return "目的: 空蝕は浄化された" if finished?

    "目的: #{target_map_title} の街核を復旧する"
  end

  def core_restored?(map_key)
    @core_restored[map_key]
  end

  def target_map_key
    CHAPTER_ORDER[@story_chapter - 1]
  end

  def target_map_title
    MAP_TITLES[target_map_key]
  end

  def npc_dialog(map_key, npc_name)
    if finished?
      return [
        "#{npc_name}: 世界が静かになったね。",
        "#{npc_name}: 共鳴士の旅は みんなの記憶に残るよ。"
      ]
    end

    if map_key == target_map_key
      [
        "#{npc_name}: 空蝕の波がこの街まで届いてる。",
        "#{npc_name}: 街核に触れて、共鳴を安定させてくれ。",
        "#{npc_name}: 街の中央広場にある光柱が目印だ。"
      ]
    else
      [
        "#{npc_name}: 次は #{target_map_title} へ向かうべきだ。",
        "#{npc_name}: 環門は左右と北側の光る床で渡れる。"
      ]
    end
  end

  def interact_core(map_key, hero)
    if core_restored?(map_key)
      return [
        "街核は安定している。",
        "淡い光が街全体を包んでいる。"
      ]
    end

    unless map_key == target_map_key
      return [
        "街核が反応しない。",
        "今は #{target_map_title} の街核を復旧する必要がある。"
      ]
    end

    restore_core!(map_key, hero)
  end

  def to_save_data
    {
      "story_chapter" => @story_chapter,
      "core_restored" => @core_restored.transform_keys(&:to_s),
      "future_revealed" => @future_revealed,
      "ending_type" => @ending_type
    }
  end

  def load_from_save_data(data)
    @story_chapter = integer_or_default(data["story_chapter"], @story_chapter)
    @story_chapter = [[@story_chapter, 1].max, CHAPTER_ORDER.size + 1].min

    saved_cores = data["core_restored"]
    if saved_cores.is_a?(Hash)
      CHAPTER_ORDER.each do |key|
        @core_restored[key] = !!saved_cores[key.to_s]
      end
    end

    @future_revealed = !!data["future_revealed"]
    @ending_type = data["ending_type"]
  end

  private

  def finished?
    @story_chapter > CHAPTER_ORDER.size
  end

  def restore_core!(map_key, hero)
    @core_restored[map_key] = true

    lines = [
      "街核に共鳴を接続した。",
      "#{MAP_TITLES[map_key]} の波形が安定した！"
    ]

    if map_key == :field_09
      @future_revealed = true
      lines << "観測ログ: 空蝕の正体は未来の主人公の残響。"
    end

    @story_chapter += 1

    if finished?
      @ending_type = if hero.companion_count >= 4
                       "true"
                     elsif hero.companion_count <= 1
                       "lonely"
                     else
                       "normal"
                     end
      lines.concat(ending_lines)
    else
      lines << "次の目的地: #{target_map_title}"
    end

    lines
  end

  def ending_lines
    case @ending_type
    when "true"
      ["真エンド: 共鳴が空蝕を浄化し、世界が再生した。"]
    when "lonely"
      ["孤独エンド: 世界は救われたが、主人公の記憶は薄れていく。"]
    else
      ["通常エンド: 空蝕は鎮まり、旅はひとまず終わりを迎えた。"]
    end
  end

  def integer_or_default(value, fallback)
    Integer(value, 10)
  rescue StandardError
    fallback
  end
end
