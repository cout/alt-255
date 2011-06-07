class DelayedOutput
  def initialize(bot, delay)
    @outgoing_queue = Queue.new
    @delay = delay
    @bot = bot
  end

  def push(s)
    @outgoing_queue.push(s)
  end

  def run
    thread = Thread.new do
      loop do
        begin
          s = @outgoing_queue.shift
          @bot.log "--> #{s}"
          @bot.sock.send "#{s}\n", 0 
          sleep @delay
        rescue Interrupt
          raise Interrupt
        rescue Exception => detail
          puts "Outgoing thread got an exception"
          puts detail.message
          puts detail.backtrace.join("\n")
      end
      end
    end
    return thread
  end
end
