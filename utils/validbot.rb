require './botdb.rb'

botdb = BotDB.new('bot.db')
puts botdb.valid_bot(ARGV[0])

