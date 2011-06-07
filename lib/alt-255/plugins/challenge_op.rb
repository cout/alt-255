class ChallengeOp < Plugin
  def initialize(bot)
    @bot = bot
    @bot.register RFC2812::RPL_WELCOME, method(:welcome_event)
  end

  def welcome_event(message)
    @bot.log "welcome event"
    # TODO: wait until we have joined the channel to send the message
    @bot.config::CHANNELS.each do |channel|
      @bot.config::BOTLIST.each do |bot|
        @bot.privmsg(bot, "CHALLENGE OP #{channel}")
      end
    end
  end
end
