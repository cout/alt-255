class Version < Plugin
  def initialize(bot)
    @bot = bot
    @bot.register_ctcp 'VERSION', method(:ctcp_version_event)
  end

  def ctcp_version_event(message)
    @bot.log "[ CTCP VERSION from #{message.source} ]"
    @bot.reply_version(message.source.nick, @version_string) unless !message.source.nick
  end

  def reply_version(user, version)
    @bot.sendmsg "NOTICE #{user} :\001#{version}\001"
  end
end
