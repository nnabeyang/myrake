#!/usr/bin/ruby -I.
require 'test/unit'
Dir["./#{ARGV.shift}/test_*.rb"].each do |file|
 Kernel.require file
end
