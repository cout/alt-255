require 'alt-255/command'
require 'alt-255/command_args'
require 'alt-255/commands'

class Commands < Plugin
  attr_reader :commands

  def initialize(bot)
    @bot = bot
    @bot.register 'PRIVMSG', method(:privmsg_event)

    # TODO: register new commands at run-time as well
    @commands = { }
    Command.commands.each do |klass|
      @commands[klass::NAME.upcase] = klass.new(@bot)
    end
  end

  def privmsg_event(message)
    return if !message.source.nick

    if @nick.upcase == message.dest.upcase then
      reply_to = message.source.nick
      public_message = false
    else
      reply_to = message.dest
      public_message = true
    end

    command, command_args = message.args[1].split(/\s+/, 2)
    cmd = @bot.commands[command.upcase]

    if cmd then
      # If this is a private-only command, then make sure it was sent to
      # us directly and not to a channel.
      return if cmd.public? and not public_message

      args = CommandArgs.new(@bot, message, reply_to, command_args)
      cmd.do(args)
    end
  end

  # Log a command; if the command does not have the LOGGABLE_COMMAND
  # flag set, then only log the command itself, and not the arguments.
  def log_command(cmd, str, user, to)
    if cmd.loggable? then
      log "[ `#{str}' from " +
      "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
    else
      log "[ `#{cmd.name}' from " +
      "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
    end
  end

end
