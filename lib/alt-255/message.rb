class Message
  attr_reader :source
  attr_reader :dest
  attr_reader :msg
  attr_reader :args

  def initialize(source, dest, msg, args)
    @source = source
    @dest = dest
    @msg = msg
    @args = args
  end
end

