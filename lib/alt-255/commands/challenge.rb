class ChallengeCommand
  NAME = 'challenge'
  HELP = 'challenge <arg>'
  PUBLIC = false
  LOGGABLE = true

  def initialize(bot)
    @botdb = bot.botdb
  end

  def do(command)
    user = command.user
    botname = "#{user.user}@#{user.host}"
    botname.untaint

    if @botdb.valid_bot(botname) then
        challenge = @botdb.get_challenge(botname)
        command.reply("YOURCHALLENGE #{challenge} #{command.args[0]}")
    else
        command.log("[ Unknown bot #{botname} requested challenge ]")
    end
  end
end

