module ROCrate
  class Exception < StandardError
    attr_reader :inner_exception

    def initialize(message, _inner_exception = nil)
      if _inner_exception
        @inner_exception = _inner_exception
        super("#{message}: #{@inner_exception.class.name} - #{@inner_exception.message}")
        set_backtrace(@inner_exception.backtrace)
      else
        super(message)
      end
    end
  end
end
