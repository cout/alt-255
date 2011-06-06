class ChallengeOp < Plugin
  def initialize(bot)
    @bot = bot

    @bot.register RPL_WELCOME, method(:welcome_event)
  end

  def welcome_event(message)
    @bot.log "welcome event"
    # Join a channel and request ops
    @bot.config::CHANNELS.each do |channel|
      @bot.join(channel)
      @botlist.each do |bot|
        @bot.privmsg(bot, "CHALLENGE OP #{channel}")
      end
    end
  end
end
