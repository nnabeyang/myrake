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
  def test_application_define_task
    app = MyRake::Application.new
    [:t1, :t2, :t3].each {|task_name|
      app.define_task(MyRake::Task, task_name) {}
    }
    assert_equal ["t1", "t2", "t3"], app.tasks.keys
  end
  def test_application_run
    ARGV.clear
    ARGV << "t2" << "t1"
    tlist = []
    app = MyRake::Application.new
    [:t1, :t2, :t3].each {|task_name|
      app.define_task(MyRake::Task, task_name) {|t| tlist << t.name }
    }
    app.run
    assert_equal ["t2", "t1"], tlist 
    ARGV.clear
  end
  def test_application_run_default
    ARGV.clear
    tlist = []
    app = MyRake::Application.new
    [:t1, :t2, :t3].each {|task_name|
      app.define_task(MyRake::Task, task_name) {|t| tlist << t.name }
    }
    app.define_task(MyRake::Task, :default) {|t| tlist << t.name }
    app.run
    assert_equal ["default"], tlist 
  end

  def test_application_clear
     app = MyRake::Application.new
    [:t1, :t2, :t3].each {|task_name|
      app.define_task(MyRake::Task, task_name) {}
    }
    assert_equal ["t1", "t2", "t3"], app.tasks.keys
    app.clear
    assert_equal({}, app.tasks)
  end
  def test_task
    ran = false
    t = task(:t1) { ran = true}
    t.invoke
    assert ran
    MyRake.application.clear
  end
  def test_load_rakefile
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path('../data', __FILE__))
    MyRake.application.load_rakefile
    assert_equal ["default", "t1", "t2"], MyRake.application.tasks.keys
    Dir.chdir(original_dir)
    MyRake.application.clear
  end
end
