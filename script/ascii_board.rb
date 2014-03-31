#!/usr/bin/env ruby

require 'multi_json'
require File.expand_path('../../lib/ascii_board.rb', __FILE__)

filename = ARGV.shift or abort "Usage: $0 JSON_FILE"
json = File.read(filename)
state_hash = MultiJson.load(json)

AsciiBoard.new(state_hash).draw
