require 'optparse'
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
      @tasks = {}
    end
    def define_task(task_class, *args, &block)
      task_name, prerequisites = resolve_args(args)
      @tasks[task_name.to_s] = task_class.new(task_name, prerequisites, &block)
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
  end
  class Task
    attr_reader :name
    def initialize(name, prerequisites, &block)
      @name = name.to_s
      @prerequisites = prerequisites
      @action = block
    end
    def invoke
      @prerequisites.each {|preq_name_sym|
        preq = MyRake.application.tasks[preq_name_sym.to_s]
        preq.invoke
      }
      @action.call(self)
    end
    class << self
      def define_task(task_name, &block)
         MyRake.application.define_task(self, task_name, &block)
      end
    end
  end
end
def task(*args, &block)
  MyRake::Task.define_task(*args, &block)
end
