class HelpCommand < Command
  NAME = 'help'
  HELP = 'help [<command>]'
  PUBLIC = false
  LOGGABLE = true

  def do(command)
    command.bot.send_help(dest, command_arg)
  end
end

