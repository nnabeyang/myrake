require 'optparse'
require 'singleton'
module MyRake  
  class << self
    def application
     @application ||= Application.new
    end
  end
  DEFAULT_RAKEFILE = 'Rakefile'
  class Application
    attr_reader :tasks
    def initialize
      @scope = []
      @tasks = {}
    end
    def current_scope
      @scope.dup
    end
    def define_task(task_class, *args, &block)
      task_name, prerequisites = resolve_args(args)
      task_name = task_class.scope_name(@scope, task_name)
      @tasks[task_name.to_s] = task_class.new(task_name, prerequisites, self, &block)
    end
    def resolve_args(args)
       if args.last.kind_of?(Hash)
         hash = args.pop
         fail "args.size should be 1" if hash.size != 1
         return hash.map {|k, v| [k, v]}.first
       else
         return [args.first, []]
       end 
    end
    def run
      handle_options
      load_rakefile
      ARGV << "default" if ARGV.empty?
      ARGV.each {|task_name|
        @tasks[task_name].invoke
      }
    end
    def handle_options
      OptionParser.new do |opts|
        opts.banner = 'myrake {options} targets...'
        opts.on_tail('-h', '--help', '-H', 'Display this help message.') do
          puts opts
          exit
        end
      end.parse! 
    end
    def clear
      @tasks.clear
    end
    def load_rakefile
      path = File.expand_path(DEFAULT_RAKEFILE)
      load path if File.exist? path
    end
    def in_namespace(ns)
      @scope << ns
      yield
    ensure
      @scope.pop
    end
    def lookup(task_name, scope)
      n = scope.size
      while n >= 0
        task = @tasks[(scope[0, n] + [task_name]).join(':')]
        return task if task
        n -= 1
      end
      nil
    end
  end
  class Task
    attr_reader :name
    attr_reader :scope
    def initialize(name, prerequisites, app, &block)
      @name = name.to_s
      @prerequisites = prerequisites
      @scope = app.current_scope
      @action = (block_given?)? block :nil
    end
    def invoke
      @prerequisites.each {|preq_name_sym|
        preq = MyRake.application.tasks[preq_name_sym.to_s]
        preq.invoke
      }
      @action.call(self) if @action && needed?
    end
    def needed?
      true
    end
    class << self
      def scope_name(scope, task_name)
        (scope + [task_name]).join(':')
      end
      def define_task(task_name, &block)
         MyRake.application.define_task(self, task_name, &block)
      end
    end
  end
  class FileTask < Task
    def timestamp 
      (File.exist?(name))? File.stat(name).mtime : MyRake::EARY
    end
    def out_of_date?
      @prerequisites.any? {|n| MyRake::application.tasks[n].timestamp > timestamp}
    end
    def needed?
      !File.exist?(name) || out_of_date?
    end
    class << self
      def scope_name(scope, task_name)
        (scope + [task_name]).join(':')
      end
    end
  end
  class Earytime
    include Singleton
    include Comparable
    def <=>(other)
      -1
    end
  end
  EARY = Earytime.instance
end
def task(*args, &block)
  MyRake::Task.define_task(*args, &block)
end
def file(*args, &block)
  MyRake::FileTask.define_task(*args, &block)
end
def namespace(ns, &block)
  MyRake.application.in_namespace(ns, &block)
end
