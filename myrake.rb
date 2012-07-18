module MyRake  
  class Application
    attr_reader :tasks
    def initialize
      @tasks = {}
    end
    def define_task(task_class, task_name, &block)
      @tasks[task_name.to_s] = task_class.new(task_name, &block)
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
  end
end

