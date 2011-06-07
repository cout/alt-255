class Console < Plugin
  def initialize(bot)
    @bot = bot

    @stdin_thread = Thread.new do
      Thread.current.abort_on_exception = true
      loop do
        s = $stdin.gets
        begin
          bot.mutex.synchronize { handle_console_input(s) }
        rescue Exception
          p $!, $!.backtrace
        end
      end
    end
  end

  def handle_console_input(s)
    case s
    when /\/(.*?)\s+(.*)/i
      cmd = $1.untaint
      args = $2.untaint
      handle_console_command(cmd, args)
    else
      @bot.sendmsg(s)
    end
  end

  def handle_console_command(cmd, args)
    case cmd
    when /eval/i
      eval(args)
    when /reload/i
      $".delete(args)
      require(args)
    else
      puts "Invalid command: #{cmd}"
    end
  end
end
