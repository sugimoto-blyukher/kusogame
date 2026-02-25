require "json"

module SaveData
  module_function

  SAVE_DIR = File.join(__dir__, "save")
  SAVE_FILE = File.join(SAVE_DIR, "slot1.json")

  def exists?
    File.file?(SAVE_FILE)
  end

  def save(hero:, map_key:, tile_x:, tile_y:, story: nil)
    Dir.mkdir(SAVE_DIR) unless Dir.exist?(SAVE_DIR)

    payload = {
      "version" => 1,
      "saved_at" => Time.now.to_i,
      "map_key" => map_key.to_s,
      "tile_x" => tile_x,
      "tile_y" => tile_y,
      "hero" => hero.to_save_data,
      "story" => story
    }

    File.write(SAVE_FILE, JSON.pretty_generate(payload))
    true
  end

  def load
    return nil unless exists?

    data = JSON.parse(File.read(SAVE_FILE))
    return nil unless data.is_a?(Hash)

    data
  rescue StandardError
    nil
  end
end
