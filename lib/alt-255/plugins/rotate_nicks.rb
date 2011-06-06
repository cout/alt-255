require 'alt255/rfc2812'

class RotateNicks < Plugin
  def initialize(bot)
    @bot = bot

    @bot.register RFC2812::ERR_NONICKNAMEGIVEN, method(:badnick_event)
    @bot.register RFC2812::ERR_ERRONEUSNICKNAME, method(:badnick_event)
    @bot.register RFC2812::ERR_NICKNAMEINUSE, method(:badnick_event)

    @nicks = bot.config::NICKS
    @current_nick = 0

    @bot.login_nick = @nicks[current_nick]
  end

  def badnick_event(message)
    bot.log "[ Bad nick; rotating nicks ]"
    @current_nick = (@current_nick + 1) % @nicks.length
    bot.nick(@nicks[@current_nick])
  end
end
