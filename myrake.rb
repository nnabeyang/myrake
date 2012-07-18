module MyRake  
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

