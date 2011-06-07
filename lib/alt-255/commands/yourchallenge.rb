class YourChallengeCommand < Command
  NAME = 'yourchallenge'
  HELP = 'yourchallenge <arg>'
  PUBLIC = false
  LOGGABLE = true

  def initialize(bot)
    @bot = bot
    @botdb = @bot.botdb
    @private_key = @bot.config::PRIVATE_KEY
  end

  def do(command)
    if command.args.length != 3 then
      command.send_help()
      return
    end

    user = command.message.source.user
    challenge = command.args[0]
    msg = command.args[1]
    msg_arg = command.args[2]

    case msg
      when "OP"
        challenge.untaint
        response = @botdb.get_response(@private_key, challenge)
        command.reply("CHALLENGEOP #{response} #{msg_arg}")
      else
        command.log("[ Unknown challenge type #{msg} from #{user.nick} ]")
    end
  end
end

