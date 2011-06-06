class CommandArgs
  attr_reader :bot
  attr_reader :message
  attr_reader :user
  attr_reader :dest
  attr_reader :str
  attr_reader :args

  def initialize(bot, message, reply_to, str)
    @bot = bot
    @message = message
    @user = user
    @reply_to = reply_to
    @str = str
    @args = str.split()
  end

  def reply(response)
    @bot.privmsg(@user, response)
  end

  def log(message)
    @bot.log(message)
  end
end

