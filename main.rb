require 'bomberman'
require './lib/ai'
require 'socket'
require 'benchmark'

socket = TCPSocket.new('localhost', 40000)

state = Bomberman::GameState.new(socket)
state.watch(proc {
  puts "turn=#{state.turn}, position=(#{state.x}, #{state.y})"
})
state.next_turn

ai = Ai.new(state)
controller = Bomberman::Controller.new(socket)
begin
  action = nil
  took = Benchmark.realtime do
    ai.update
    action = ai.next_action
    controller.send(action) if action
  end
  puts "turn #{state.turn} action #{action} took #{took}/#{state.turn_duration / 1000_000_000.0}"
end while state.next_turn
