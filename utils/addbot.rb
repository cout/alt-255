require './botdb.rb'

bot = ARGV[0]
puts "Enter public key, end with Ctrl-D:"
key = STDIN.readlines.join
botdb = BotDB.new("bot.db")
botdb.add_bot(bot, key)
