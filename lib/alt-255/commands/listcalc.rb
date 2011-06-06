class ListcalcCommand < Command
  NAME = 'listcalc'
  HELP = 'listcalc <calc>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    pattern = command.str

    if pattern =~ /[^\w\d.+*?()\[\]_^$-]/ then
      command.reply("Invalid pattern")
      return
    end

    begin
      regex = /#{pattern}/i
    rescue SyntaxError, RegexpError
      command.reply($!)
      return
    end

    result = @calcdb.listcalc(regex, 25)
    if result.size == 0 then
      command.reply("No entries found")
    else
      command.reply(result.join(' '))
    end
  end
end
