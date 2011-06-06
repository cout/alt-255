class CONFIG
    # SERVER        = 'irc.carrier1.net.uk'
    # SERVER          = 'irc.homelien.no'
    # SERVER          = 'irc.daxnet.no'
    # SERVER          = 'irc.efnet.org'
    SERVER          = 'irc.efnet.nil'
    PORT            = 6667
    NICKS           = [ 'Alt-255', 'Alt-255_' ]
    USER            = 'Alt-255'
    REAL_NAME       = 'Alt-255'
    # CHANNELS        = [ '#c', '#code-poets' ]
    CHANNELS        = [ '#alt-255' ]
    # BOTLIST         = [ 'Alt-255', 'cout' ]
    BOTLIST         = []
    PRIVATE_KEY     = File.readlines(File.join(__FILE__, 'private_key.pem'))
    TIMESTAMP       = true
    RECONNECT_DELAY = 300
    PING_INTERVAL   = 300
    PING_TIMEOUT    = 600
end
