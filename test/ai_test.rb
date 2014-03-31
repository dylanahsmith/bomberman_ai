require 'test_helper'

=begin

The board for the simple.json looks like the following

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

    update_for_action(:left)
    set_cell(@state['LastX'], @state['LastY'], 'Bomb')
    assert_equal :down, @ai.next_action

    update_for_action(:down)
    assert_equal nil, @ai.next_action

    set_cell(1, 1, 'Flame')
    set_cell(1, 2, 'Flame')
    @state['Bombs'] -= 1
    assert_equal nil, @ai.next_action
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
    end
    set_cell(@state['LastX'], @state['LastY'], 'Ground')
    set_cell(@state['X'], @state['Y'], 'p1')
    @game_state.update(@state)
    @ai.update
  end

  def set_cell(x, y, name)
    @state['Board'][x][y]['Name'] = name
  end
end
