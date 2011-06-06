require 'alt-255/bot'
require 'etc/config'

CONFIG.untaint
CONFIG.constants.each do |x|
    Kernel::eval "CONFIG::#{x}.untaint"
end

bot = IRC_Bot.new(CONFIG)
bot.run()
