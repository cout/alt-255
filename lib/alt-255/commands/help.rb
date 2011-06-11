class HelpCommand < Command
  NAME = 'help'
  HELP = 'help [<command>]'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    bot = command.bot
    arg = command.args[0]

    if arg then
      cmd = Command.commands[arg.upcase]
      if cmd then
        command.reply("Usage: #{cmd.help}")
      else
        command.reply("No such command")
      end
    else
      commands = Command.commands.map { |cmd| cmd::NAME }
      command.reply(commands.join(' '))
    end
  end
end

