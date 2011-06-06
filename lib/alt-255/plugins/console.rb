class Console < Plugin
  def initialize(bot)
    @stdin_thread = Thread.new do
      Thread.current.abort_on_exception = true
      puts "starting stdin thread"
      loop do
        s = $stdin.gets
        bot.mutex.synchronize do
          handle_console_input(s)
        end
      end
    end
  end

  def handle_console_input(s)
    case s
    when /\/(.*?)\s+(.*)/i
      cmd = $1
      args = $2
      case cmd
      when /eval/i
        eval(args.untaint)
      else
        puts "Invalid command: #{cmd}"
      end 
    else
      send(s)
    end
  end
end
