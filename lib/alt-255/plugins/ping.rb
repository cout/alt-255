class Ping < Plugin
  def initialize(bot)
    @bot = bot
    @ping_interval = bot.config::PING_INTERVAL

    @bot.register 'PING', method(:ping_event)
    @bot.register_ctcp 'PING', method(:ctcp_ping_event)

    # TODO: start thread only after connected
    # TODO: kill ping thread at shutdown
    @ping_thread = Thread.new do
      Thread.current.abort_on_exception = true
      puts "starting ping thread"
      loop do
        @bot.mutex.synchronize { send_ping }
        sleep @ping_interval
      end
    end
  end

  def send_ping
    if @bot.sock then
      @bot.sendmsg "PING :localhost"
    end
  end

  def ping_event(message)
    @bot.log "[ Server ping ]"
    @bot.sendmsg "PONG :#{message.source}"
  end

  def ctcp_ping_event(message)
    @bot.log "[ CTCP PING #{message.args} from #{message.source} ]"
    @bot.reply_ping(message.source.nick, message.args[0]) unless !message.source.nick
  end
end

