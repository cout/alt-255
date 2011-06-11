class CommandArgs
  attr_reader :bot
  attr_reader :message
  attr_reader :reply_to
  attr_reader :str
  attr_reader :args

  def initialize(bot, message, reply_to, str)
    @bot = bot
    @message = message
    @reply_to = reply_to
    @str = str
    @args = str ? str.split() : [ ]
  end

  def reply(response)
    @bot.privmsg(@reply_to, response)
  end

  def log(message)
    @bot.log(message)
  end
end

