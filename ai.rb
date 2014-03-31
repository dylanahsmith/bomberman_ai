require 'bomberman'
require 'set'

Cell = Struct.new(:flags, :type)
Bomb = Struct.new(:player, :radius, :turn, :pos)
Player = Struct.new(:player, :radius, :last_turn, :pos, :last_pos)

class Ai
  def initialize(state)
    @state = state
    @width = state.board.size
    @height = state.board[0].size
    cell_count = @width * @height
    @cells = cell_count.times.map{ |i| Cell.new }
    @bombs = []
    @players = []
    @powerups = []

    @wait_for = nil
  end

  CELL_PLAYER = 1
  CELL_BOMB = 2
  CELL_POWERUP = 4
  CELL_TRAVERSIBLE = 8
  CELL_SHEILD = 0x10
  CELL_DANGER = 0x20
  CELL_BOMB_CHECK = 0x40

  CELL_NAMES = {
    "Wall" => [:wall, CELL_SHEILD],
    "Rock" => [:rock, CELL_SHEILD],
    "Ground" => [:ground, CELL_TRAVERSIBLE],
    "Bomb" => [:bomb, CELL_BOMB],
    "PowerUp(Radius)" => [:powerup_radius, CELL_POWERUP | CELL_TRAVERSIBLE],
    "PowerUp(Bomb)" => [:powerup_bomb, CELL_POWERUP | CELL_TRAVERSIBLE],
    "Flame" => [:flame, 0],
    "p1" => [:p1, CELL_PLAYER | CELL_TRAVERSIBLE],
    "p2" => [:p2, CELL_PLAYER | CELL_TRAVERSIBLE],
    "p3" => [:p3, CELL_PLAYER | CELL_TRAVERSIBLE],
    "p4" => [:p4, CELL_PLAYER | CELL_TRAVERSIBLE],
  }

  def update
    powerups = []
    players = []
    bombs = []
    @state.board.each_with_index do |column, x|
      column.each_with_index do |cell_hash, y|
        i = idx_from_coord(x, y)
        cell = @cells[i]
        cell.type, cell.flags = CELL_NAMES[cell_hash['Name']]
        if (cell.flags & (CELL_POWERUP | CELL_PLAYER | CELL_BOMB)) != 0
          if (cell.flags & CELL_POWERUP) != 0
            powerups << i
          elsif (cell.flags & CELL_PLAYER) != 0
            players << i
          elsif (cell.flags & CELL_BOMB) != 0
            bombs << i
          end
        end
      end
    end
    if @state.last_x == @state.x && @state.last_y == @state.y &&
       @bombs.include?(idx_from_coord(@state.x, @state.y))
      bombs << idx_from_coord(@state.x, @state.y)
    end
    @powerups = powerups
    @players = players
    @bombs = bombs
    mark_bomb_paths
  end

  def coord_from_idx(idx)
    x = idx % @width
    y = idx / @width
    [x, y]
  end

  def idx_from_coord(x, y)
    x + y * @width
  end

  def walk_bomb_path(bomb_idx)
    yield bomb_idx
    i = bomb_idx - 1
    until (@cells[i].flags & CELL_SHEILD) != 0
      yield i
      i -= 1
    end
    i = bomb_idx + 1
    until (@cells[i].flags & CELL_SHEILD) != 0
      yield i
      i += 1
    end
    i = bomb_idx - @width
    until (@cells[i].flags & CELL_SHEILD) != 0
      yield i
      i -= @width
    end
    i = bomb_idx + @width
    until (@cells[i].flags & CELL_SHEILD) != 0
      yield i
      i += @width
    end
  end

  def mark_bomb_paths
    @bombs.each do |bomb_idx|
      walk_bomb_path(bomb_idx) do |i|
        @cells[i].flags |= CELL_DANGER
      end
    end
  end

  def in_danger?(pos)
    (@cells[pos].flags & CELL_DANGER) != 0
  end

  def breadth_first_search(pos)
    queue = [[nil, pos]]
    seen = [pos].to_set
    while item = queue.shift
      dir, pos = item
      return dir if yield pos
      [[:left, pos - 1], [:right, pos + 1], [:up, pos - @width], [:down, pos + @width]].each do |dir2, i|
        queue << [dir || dir2, i] if (@cells[i].flags & CELL_TRAVERSIBLE) != 0 && seen.add?(i)
      end
    end
    nil
  end

  def escape_dir(pos)
    breadth_first_search(pos) do |i|
      (@cells[i].flags & CELL_DANGER) == 0
    end
  end

  def safe_to_bomb?(pos)
    walk_bomb_path(pos) do |i|
      @cells[i].flags |= CELL_BOMB_CHECK
    end
    breadth_first_search(pos) do |i|
      (@cells[i].flags & (CELL_DANGER|CELL_BOMB_CHECK)) == 0
    end
  end

  def available_movements(pos)
    dirs = []
    dirs << :up if (@cells[pos - @width].flags & (CELL_TRAVERSIBLE|CELL_DANGER)) == CELL_TRAVERSIBLE
    dirs << :down if (@cells[pos + @width].flags & (CELL_TRAVERSIBLE|CELL_DANGER)) == CELL_TRAVERSIBLE
    dirs << :left if (@cells[pos - 1].flags & (CELL_TRAVERSIBLE|CELL_DANGER)) == CELL_TRAVERSIBLE
    dirs << :right if (@cells[pos + 1].flags & (CELL_TRAVERSIBLE|CELL_DANGER)) == CELL_TRAVERSIBLE
    dirs
  end

  def last_dir
    if @state.last_x != @state.x
      @state.last_x < @state.x ? :left : :right
    elsif @state.last_y != @state.y
      @state.last_y < @state.y ? :up : :down
    end
  end

  def next_action
    pos = idx_from_coord(@state.x, @state.y)
    if @wait_for
      type, value = @wait_for
      done = case type
      when :bombs
        @state.bombs == value
      when :pos
        pos == value
      end
      return nil unless done
      @wait_for = nil
    end

    action = if in_danger?(pos)
      escape_dir(pos)
    elsif @state.bombs < @state.max_bombs && safe_to_bomb?(pos)
      @bombs << pos
      :bomb
    else
      dirs = available_movements(pos)
      dirs.delete(last_dir) if dirs.size > 1
      dirs.sample
    end
    @wait_for = case action
    when :bomb
      [:bombs, @state.bombs + 1]
    when :left
      [:pos, pos - 1]
    when :right
      [:pos, pos + 1]
    when :up
      [:pos, pos - @width]
    when :down
      [:pos, pos + @width]
    end
    action
  end
end
