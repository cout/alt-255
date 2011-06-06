class DelayedOutput
  def initialize(delay)
    @outgoing_queue = Queue.new
    @delay = delay
  end

  def run
    thread = Thread.new do
      loop do
        begin
          s = @outgoing_queue.shift
          log "--> #{s}"
          send_impl(s)
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
