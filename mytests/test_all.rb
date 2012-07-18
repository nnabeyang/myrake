#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'test/unit'
require 'myrake'
require 'stringio'
BASEDIR = File.dirname(__FILE__)
class MyRakeTests < Test::Unit::TestCase
  def test_create_task
    ran = false
    t = MyRake::Task.new(:task) {|t|
      assert_equal "task", t.name
      ran = true
    }
    t.invoke
    assert ran
  end
end
