class Manager
  def initialize(options = {})
    @responded = false
    
    options.each do |key, value|
      send("#{key}=", value)
    end
  end
  
  def respond(response = nil, *args)
    @responded = true
    @responder.respond(response, *args)
  end
  
  def invoke!(action, &block)
    @responder = Responder.new(block) if block
    send(action) if respond_to?(action)
    respond if @responder and not @responded
  end
  
  class Responder
    def initialize(block)
      @block = block
    end
    
    def respond(response, *args)
      @response = response
      @args = args
      @block.call(self)
    end
    
    def method_missing(response, &block)
      if @response == response
        block.call(*@args)
      end
    end
  end
end