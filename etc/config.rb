class CONFIG
  # SERVER        = 'irc.carrier1.net.uk'
  # SERVER          = 'irc.homelien.no'
  # SERVER          = 'irc.daxnet.no'
  # SERVER          = 'irc.efnet.org'
  SERVER          = 'irc.efnet.nl'
  PORT            = 6667
  NICKS           = [ 'alt255', 'alt255_' ]
  USER            = 'alt255'
  REAL_NAME       = 'Alt255'
  # CHANNELS        = [ '#c', '#code-poets' ]
  CHANNELS        = [ '#alt-255' ]
  # BOTLIST         = [ 'Alt-255', 'cout' ]
  BOTLIST         = []
  PRIVATE_KEY     = File.readlines(File.join(File.dirname(__FILE__), 'private_key.pem'))
  USER_DB         = File.join(File.dirname(__FILE__), 'users.db')
  BOT_DB          = File.join(File.dirname(__FILE__), 'bots.db')
  CALC_DB         = File.join(File.dirname(__FILE__), 'calcdb.data')
  TIMESTAMP       = true
  RECONNECT_DELAY = 300
  PING_INTERVAL   = 300
  PING_TIMEOUT    = 600
  DELAY           = 0.1
  COMMAND_PREFIX  = 'alt255:'
end
