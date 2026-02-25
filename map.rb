class Map
  attr_reader :mapdata, :size_x, :size_y

  def initialize(source)
    @mapdata =
      case source
      when String
        read_from_file(source)
      when Array
        normalize_rows(source)
      else
        raise ArgumentError, "unsupported map source: #{source.class}"
      end

    finalize_size
  end

  def self.from_rows(rows)
    new(rows)
  end

  def in_bounds?(x, y)
    x >= 0 && y >= 0 && x < @size_x && y < @size_y
  end

  def [](x, y)
    return nil unless in_bounds?(x, y)

    @mapdata[y][x]
  end

  def []=(x, y, value)
    return unless in_bounds?(x, y)

    @mapdata[y][x] = value
  end

  def draw(tiles, camera_x, camera_y, viewport_x, viewport_y, viewport_w, viewport_h, z)
    return if @size_x.zero? || @size_y.zero?
    return if tiles.empty?

    tile_w = 32
    tile_h = 32

    start_tx = [camera_x / tile_w, 0].max
    start_ty = [camera_y / tile_h, 0].max
    end_tx = [(camera_x + viewport_w) / tile_w + 1, @size_x - 1].min
    end_ty = [(camera_y + viewport_h) / tile_h + 1, @size_y - 1].min

    (start_ty..end_ty).each do |ty|
      (start_tx..end_tx).each do |tx|
        tile_index = @mapdata[ty][tx]
        next if tile_index.nil?

        tile = tiles[tile_index % tiles.size]
        next if tile.nil?

        draw_x = viewport_x + tx * tile_w - camera_x
        draw_y = viewport_y + ty * tile_h - camera_y
        tile.draw(draw_x, draw_y, z)
      end
    end
  end

  private

  def read_from_file(filename)
    @mapdata = []

    File.open(filename, "rt") do |fh|
      fh.each_line do |line|
        stripped = line.strip
        next if stripped.empty?

        @mapdata << parse_row(stripped)
      end
    end

    normalize_rows(@mapdata)
  end

  def parse_row(line)
    if line.include?(",")
      line.split(",").map { |cell| parse_cell(cell) }
    else
      line.each_char.map { |cell| parse_cell(cell) }
    end
  end

  def parse_cell(cell)
    token = cell.to_s.strip
    return nil if token.empty? || token == "x"
    return nil if token.start_with?("#")
    Integer(token, 10)
  rescue ArgumentError
    nil
  end

  def normalize_rows(rows)
    rows.map do |row|
      row.map do |cell|
        if cell.nil?
          nil
        elsif cell.is_a?(Integer)
          cell
        else
          Integer(cell.to_s, 10)
        end
      rescue ArgumentError, TypeError
        nil
      end
    end
  end

  def finalize_size
    @size_y = @mapdata.size
    @size_x = @mapdata[0]&.size || 0
  end
end
