class ChpassCommand < Command
  NAME = 'chpass'
  HELP = 'chpass <user> <oldpass> <oldpass>'
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

    user = command.args[0]
    oldpass = command.args[1]
    newpass = command.args[2]

    username.untaint
    oldpass.untaint
    newpass.untaint
    if @userdb.change_pass(username, oldpass, newpass) then
      command.reply("Password changed")
    end
  end
end
