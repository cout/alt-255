require 'alt-255/bot'
require 'etc/config'

CONFIG.untaint
CONFIG.constants.each do |x|
    Kernel::eval "CONFIG::#{x}.untaint"
end
loop do
  begin
    puts "Starting bot..."
    $bot = IRC_Bot.new(CONFIG)
    $bot.run()
  rescue Exception
    p $!, $!.message
  end
  GC.start
  sleep CONFIG::RECONNECT_DELAY
end


