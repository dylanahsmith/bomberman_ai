class AsciiBoard
  CELLS = {
    "Wall" => "#",
    "Rock" => "*",
    "Ground" => " ",
    "Bomb" => "ß",
    "PowerUp(Radius)" => "€",
    "PowerUp(Bomb)" => "$",
    "Flame" => "+",
    "p1" => "p",
    "p2" => "p",
    "p3" => "p",
    "p4" => "p",
  }

  def initialize(state_hash)
    @state_hash = state_hash
  end

  def draw
    board = @state_hash['Board']
    width = board.size
    height = board[0].size
    height.times do |y|
      width.times do |x|
        cell_name = board[x][y]['Name']
        print(CELLS[cell_name] || "?")
      end
      puts
    end
  end
end
