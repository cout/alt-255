class Join < Plugin
  def initialize(bot)
    @bot = bot
    @bot.register RFC2812::RPL_WELCOME, method(:welcome_event)
  end

  def welcome_event(message)
    @bot.config::CHANNELS.each do |channel|
      @bot.join(channel)
    end
  end
end
