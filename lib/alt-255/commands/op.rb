class OpCommand < Command
  NAME = 'op'
  HELP = 'op <channel> <user> <pass>'
  PUBLIC = false
  LOGGABLE = false

  def initialize(bot)
    @userdb = bot.userdb
  end

  def do(command)
    if command.args.length != 3 then
      command.send_help()
      return
    end

    channel = command.args[0]
    username = command.args[1]
    pass = command.args[2]

    username.untaint
    pass.untaint

    if @userdb.validate_user(username, pass) then
      command.bot.sendmsg "MODE #{channel} +o :#{user.nick}"
    else
      command.log "[ Invalid user or pass ]"
    end
  end
end
