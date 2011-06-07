class CalcCommand < Command
  NAME = 'calc'
  HELP = 'calc <calc>'
  PUBLIC = true
  LOGGABLE = true

  def initialize(bot)
    @calcdb = bot.calcdb
  end

  def do(command)
    calc = nil

    case command.str
    when /^(\S+)\s+to\s+(\w+)/i
      # Only allow 'to' if the message came from in-channel
      if dest =~ /^#/ then
        calc = $1
        dest = $2
      else
        command.reply("'to' allowed only within channel")
        return
      end
    when /(\S+)/
      calc = $1
      dest = command.reply_to
    else
      command.send_help()
      return
    end

    str = @calcdb.calc(calc)
    str = "Calc not found: #{calc}" if not str
    command.bot.privmsg(dest, str)
  end
end
