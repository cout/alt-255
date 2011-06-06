class Ping < Plugin
  def initialize(bot)
    @bot = bot

    @bot.register 'PING', method(:ping_event)
    @bot.register_ctcp 'PING', method(:ctcp_ping_event)

    # TODO: kill ping thread at shutdown
    @ping_thread = Thread.new do
      Thread.current.abort_on_exception = true
      puts "starting ping thread"
      loop do
        @bot.mutex.synchronize do
          send "PING :localhost"
        end
        GC.start
        sleep @ping_interval
      end
    end
  end

  def ping_event(message)
    bot.log "[ Server ping ]"
    bot.send "PONG :#{message.source}"
  end

  def ctcp_ping_event(message)
    bot.log "[ CTCP PING #{message.args} from #{message.source} ]"
    bot.reply_ping(message.source.nick, message.args[0]) unless !message.source.nick
  end

  def reply_ping(user, str)
    bot.send "NOTICE #{user} :\001PING #{str}\001"
  end
end

