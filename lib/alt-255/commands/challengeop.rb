# Respond to a challenge
# Request ops using challenge/response authentication
class ChallengeOpCommand < Command
  NAME = 'challengeop'
  HELP = 'challengeop <challenge_response> <channel>'
  PUBLIC = false
  LOGGABLE = true

  def initialize(bot)
    @botdb = bot.botdb
  end

  def do(command)
    if command.args.length != 2 then
      command.send_help()
      return
    end

    user = command.message.source.user
    response = command.args[0]
    channel = command.args[1]

    botname = "#{user.user}@#{user.host}"
    botname.untaint
    if @botdb.valid_bot(botname) then
      if @botdb.validate_bot(botname, response) then
        command.send("MODE #{channel} +o :#{user.nick}")
      else
        command.log("[ Invalid op response from #{botname} ]")
      end
    else
      command.log("[ Unknown user #{botname} requested ops ]")
    end
  end
end
