require 'test_helper'

=begin

The board for the simple.json fixture looks like the following

######
#p  *#
# # ##
#* **#
# # ##
######

=end

STATE_JSON = File.read(File.expand_path('../fixtures/simple.json', __FILE__))

class AiTest < MiniTest::Unit::TestCase
  def setup
    @state = MultiJson.decode(STATE_JSON)
  end

  def test_cornered_start
    @state['Board'][3][1]['Name'] = 'Rock'
    load_state(@state)
    action = @ai.next_action
    assert [:down, :right].include?(action), "unexpected action #{action}"

    update_for_action(:right)
    assert_equal :bomb, @ai.next_action

    update_for_action(:bomb)
    assert_equal :left, @ai.next_action

    update_for_action(:left) do
      set_cell(@state['LastX'], @state['LastY'], 'Bomb')
    end
    assert_equal :down, @ai.next_action

    update_for_action(:down)
    assert_equal nil, @ai.next_action

    update_for_action(nil) do
      set_cell(1, 1, 'Flame')
      set_cell(1, 2, 'Flame')
      @state['Bombs'] -= 1
    end
    assert_equal nil, @ai.next_action
  end

  def test_open_start
    load_state(@state)
    assert_equal :bomb, @ai.next_action
    update_for_action(:bomb)

    assert_equal :right, @ai.next_action
    update_for_action(:right) do
      set_cell(@state['LastX'], @state['LastY'], 'Bomb')
    end

    assert_equal :right, @ai.next_action
    update_for_action(:right)

    assert_equal :down, @ai.next_action
    update_for_action(:down)

    assert_equal nil, @ai.next_action
  end

  def test_avoid_walking_back_into_explosion
    @state['Board'][1][1]['Name'] = 'Ground'
    @state['Board'][1][2]['Name'] = 'Bomb'
    @state['Board'][3][1]['Name'] = 'p1'
    @state['Board'][3][2]['Name'] = 'Rock'
    @state['X'] = 3
    @state['Y'] = 1
    @state['LastX'] = 2
    @state['LastY'] = 1
    @state['Bombs'] = 1
    @state['Turn'] = 5
    load_state(@state)

    assert_equal :left, @ai.next_action
    update_for_action(:left)

    assert_equal :right, @ai.next_action

    @state['Bombs'] = 0
    @state['Board'][1][1]['Name'] = 'Flame'
    @state['Board'][1][2]['Name'] = 'Flame'
    assert_equal :right, @ai.next_action
  end

  private

  def load_state(state)
    @game_state = Bomberman::GameState.new(nil)
    @game_state.update(state)
    @ai = Ai.new(@game_state)
    @ai.update
  end

  def update_for_action(action)
    @state['LastX'] = @state['X']
    @state['LastY'] = @state['Y']
    @state['Turn'] += 1
    case action
    when :left
      @state['X'] -= 1
    when :right
      @state['X'] += 1
    when :up
      @state['Y'] -= 1
    when :down
      @state['Y'] += 1
    when :bomb
      @state['Bombs'] += 1
    when nil
    end
    set_cell(@state['LastX'], @state['LastY'], 'Ground')
    set_cell(@state['X'], @state['Y'], 'p1')
    @game_state.update(@state)
    yield if block_given?
    @ai.update
  end

  def set_cell(x, y, name)
    @state['Board'][x][y]['Name'] = name
  end
end
