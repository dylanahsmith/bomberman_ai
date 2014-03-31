require 'bomberman'
require './lib/ai'
require 'socket'

socket = TCPSocket.new('localhost', 40000)

state = Bomberman::GameState.new(socket)
state.watch(proc {
  puts "turn=#{state.turn}, position=(#{state.x}, #{state.y})"
})
state.next_turn

ai = Ai.new(state)
controller = Bomberman::Controller.new(socket)
begin
  ai.update
  action = ai.next_action
  puts "turn #{state.turn} action #{action}"
  controller.send(action) if action
end while state.next_turn
