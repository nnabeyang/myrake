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
    def define_task(task_class, task_name, &block)
      @tasks[task_name.to_s] = task_class.new(task_name, &block)
    end
    def run
      load_rakefile
      ARGV << "default" if ARGV.empty?
      ARGV.each {|task_name|
        @tasks[task_name].invoke
      }
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
    def initialize name, &block
      @name = name.to_s
      @action = block
    end
    def invoke
      @action.call(self)
    end
    class << self
      def define_task(task_name, &block)
         MyRake.application.define_task(self, task_name, &block)
      end
    end
  end
end
def task(task_name, &block)
  MyRake::Task.define_task(task_name, &block)
end
