class SearchCommand < Command
  NAME = 'searchcalc'
  HELP = 'searchcalc <calc>'
  PUBLIC = true
  LOGGABLE = true

  def initialize(bot)
    @calcdb = bot.calcdb
  end

  def do(command)
    pattern = command.str

    if pattern =~ /[^\w\d.+*?()\[\]_^$-]/ then
      privmsg(dest, "Invalid pattern")
      return
    end

    begin
      regex = /#{pattern}/i
    rescue SyntaxError, RegexpError
      privmsg(dest, $!)
      return
    end

    result = @calcdb.searchcalc(regex, 25)
    if result.size == 0 then
      command.reply("No entries found")
    else
      command.reply(result.join(' '))
    end
  end
end
