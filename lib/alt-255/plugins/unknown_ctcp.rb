class UnknownCtcp < Plugin
  def initialize(bot)
    @bot = bot
    @bot.register_default_ctcp method(:unknown_ctcp_event)
  end

  def unknown_ctcp_event(message)
    @bot.log "[ unknown CTCP #{message.msg} from #{message.source} ]"
  end
end
