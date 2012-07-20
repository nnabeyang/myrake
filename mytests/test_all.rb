#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'test/unit'
require 'myrake'
require 'stringio'
require 'fileutils'
BASEDIR = File.dirname(__FILE__)
class MyRakeTests < Test::Unit::TestCase
  def test_create_task
    ran = false
    t = MyRake::Task.new(:task, [], MyRake::Application.new) {|t|
      assert_equal "task", t.name
      ran = true
    }
    t.invoke
    assert ran
  end
  def test_application_define_task
    assert_equal(["t1", "t2", "t3"], MyRake::Application.new.instance_eval{
      [:t1, :t2, :t3].each {|task_name|
        define_task(MyRake::Task, task_name) {}
      }
      @tasks.keys
    })
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
    assert_equal({}, MyRake::Application.new.instance_eval {
      [:t1, :t2, :t3].each {|task_name|
        define_task(MyRake::Task, task_name) {}
      }
      clear
      @tasks
    })
  end
  def test_task
    ran = false
    t = task(:t1) { ran = true}
    t.invoke
    assert ran
    MyRake.application.clear
  end
  def test_application_resolve_args
    app = MyRake::Application.new
    assert_equal [:t1, [:t2, :t3]], app.instance_eval{ resolve_args([{:t1 => [:t2, :t3]}])}
    assert_equal [:t1, []], app.instance_eval{ resolve_args([:t1])}
  end
  def test_task_prerequisites
    runlist = [] 
    t1 = task(:t1 => [:t2, :t3]) {|t| runlist << t.name}
    t2 = task(:t2) {|t| runlist << t.name}
    t3 = task(:t3) {|t| runlist << t.name}
    t1.invoke
    assert_equal ["t2", "t3", "t1"], runlist
    MyRake.application.clear
  end
  def test_task_noblock
    runlist = []
    t1 = task(:t1 => [:t2, :t3]) 
    task(:t2) {|t| runlist << t.name}
    task(:t3) {|t| runlist << t.name}
    t1.invoke
    assert_equal ["t2", "t3"], runlist
    MyRake.application.clear
  end
  def test_filetask_of_existing_file_without_prerequsites
    MyRake.application.clear
    fn = "testdata/dummy"
    ran = false
    ft = file fn do ran = true end
    File.delete(fn) rescue nil
    open(fn, "w") {|f| f.puts "HI" }
    ft.invoke
    assert !ran
    File.delete(fn) rescue nil
  end
  def test_file_need
    MyRake.application.clear
    fn = "testdata/dummy"
    ft = file fn
    assert_equal fn, ft.name
    File.delete(fn) rescue nil
    assert ft.needed?
    open(fn, "w") {|f| f.puts "HI" }
    assert !ft.needed?
    File.delete(fn) rescue nil
  end
  OLD = "testdata/old"
  NEW = "testdata/new"
  def test_file_new_depends_on_old
    File.delete(OLD) rescue nil
    File.delete(NEW) rescue nil
    FileUtils.touch OLD
    otime = File.stat(OLD).mtime
    sleep(0.1)
    FileUtils.touch NEW
    while otime >= File.stat(NEW).mtime
      sleep(0.1)
      FileUtils.touch NEW
    end
    MyRake.application.clear
    t1 = file NEW => [OLD]
    t2 = file OLD
    assert !t1.needed?
    assert !t2.needed?
  end
  def test_file_old_depends_on_new
    File.delete(OLD) rescue nil
    File.delete(NEW) rescue nil
    FileUtils.touch OLD
    otime = File.stat(OLD).mtime
    sleep(0.1)
    FileUtils.touch NEW
    while otime >= File.stat(NEW).mtime
      sleep(0.1)
      FileUtils.touch NEW
    end
    MyRake.application.clear
    t1 = file NEW
    t2 = file OLD => [NEW]
    assert !t1.needed?
    assert t2.needed?
  end
  def test_namespace
    MyRake.application.clear
    t1 = nil
    namespace 'ns' do
      t1 = task :t1
    end
    assert_equal "ns:t1", t1.name
    assert_equal ["ns"], t1.scope
  end
  def test_namespace_resolve_prerequisites
    MyRake.application.clear
    t1 = nil
    runlist = []
    namespace 'ns' do
      t1 = task :t1 => [:t2, :t3]
      task :t2 do|t| runlist << t.name end
    end
    task :t3 do|t| runlist << t.name end
    t1.invoke
    assert_equal ["ns:t2", "t3"], runlist 
  end
  def test_application_lookup
    MyRake.application.clear
    t1 = nil
    t2 = nil
    namespace 'ns' do
      t1 = task :t1
      t2 = task :t2
    end
    assert_nil MyRake.application.lookup("no_such_task", t1.scope)
    assert_equal t2, MyRake.application.lookup("t2", t1.scope)
    assert_equal t2, MyRake.application.lookup("ns:t2", [])
  end
  def test_load_rakefile
    MyRake.application.clear
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path('../data', __FILE__))
    ARGV.clear
    ARGV << "default"
    $stdout = StringIO.new
    MyRake.application.instance_eval{
      load_rakefile
      invoke_tasks
    }
    assert_equal "t1\nt2\ndefault\n", $stdout.string
    $stdout = STDOUT 
    Dir.chdir(original_dir)
    MyRake.application.clear
    ARGV.clear
  end
end
