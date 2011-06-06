class HelpCommand < Command
  NAME = 'help'
  HELP = 'help [<command>]'
  PUBLIC = false
  LOGGABLE = true

  def do(command)
    bot = command.bot
    arg = command.args[0]

    if arg then
      cmd = bot.commands[arg.upcase]
      if cmd then
        command.reply("Usage: #{cmd.help}")
      else
        command.reply("No such command")
      end
    else
      command.reply(bot.commands.keys)
    end
  end
end

