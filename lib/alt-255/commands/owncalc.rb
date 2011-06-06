class OwncalcCommand < Command
  NAME = 'owncalc'
  HELP = 'owncalc <calc>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    owner = @calcdb.owncalc(calc)
    if owner then
      command.reply("#{calc} is owned by #{owner}")
    else
      command.reply("Calc not found: #{calc}")
    end
  end
end
