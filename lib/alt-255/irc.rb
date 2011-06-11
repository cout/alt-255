require 'alt-255/rfc2812'
require 'alt-255/message'
require 'alt-255/source'
require 'alt-255/callbacks'

require 'socket'

# The irc class, which talks to the server and holds the main event loop.
# Through this class, a client can register for events and respond to them.
class IRC
  include RFC2812

  attr_reader :mutex
  attr_reader :sock

  def initialize(server, port)
    @mutex = Mutex.new

    @server = server
    @port = port

    @callbacks = Callbacks.new
    @ctcp_callbacks = Callbacks.new

    @nick = nil
  end

  attr_reader :server, :port

  # Register for a server message.  The msg argument can be either a
  # string (for string server messages) or a number (for numeric
  # server messages).
  def register(msg, callback)
    key = msg.kind_of?(Numeric) \
    ? ("%03d" % msg)          \
    : msg.to_s.upcase
    @callbacks.add(key, callback)
  end

  # Set the default callback for unhandled messages (server messages for
  # which there is no registered callback).
  def register_default(callback)
    @callbacks.add_default(callback)
  end

  # Register for a server message.  The msg argument can be either a
  # string (for string server messages) or a number (for numeric
  # server messages).
  def register_ctcp(msg, callback)
    @ctcp_callbacks.add(msg.to_s.upcase, callback)
  end

  # Set the default callback for unhandled messages (server messages for
  # which there is no registered callback).
  def register_default_ctcp(callback)
    @ctcp_callbacks.add_default(callback)
  end

  # Connect to the IRC server
  def connect()
    @sock = TCPSocket.open(@server, @port)
  end

  # Log in to the IRC server
  def login(user, nick, real_name, flags=8)
    sendmsg "USER #{user} #{flags} * :#{real_name}"
    sendmsg "NICK #{nick}"
  end

  # Just keep on truckin' until we disconnect
  def run()
    loop do
      s = @sock.gets
      break if s.nil?
      @mutex.synchronize { handle_server_input(s) }
    end
  end

  # Change the current nick
  def nick(nick)
    @nick = nick
    sendmsg("NICK #{nick}")
  end

  # Send a message to the irc server and print it to the screen
  def sendmsg(s)
    @sock.send "#{s}\n", 0 
  end

  # Send a message to a user or a channel
  def privmsg(destination, s)
    sendmsg "PRIVMSG #{destination} :#{s}"
  end

  # Join a channel
  def join(channel)
    sendmsg "JOIN #{channel}"
  end

  # Leave a channel
  def part(channel)
    sendmsg "PART #{channel}"
  end

  # Change the topic on a channel
  def topic(channel, str)
    sendmsg "TOPIC #{channel} :#{str}"
  end

  # Respond to a ping request
  def reply_ping(user, str)
    sendmsg "NOTICE #{user} :\001PING #{str}\001"
  end

  # Respond to a version request
  def reply_version(user, version)
    sendmsg "NOTICE #{user} :\001#{version}\001"
  end

  # Quit with a message
  def quit(message="")
    sendmsg "QUIT :#{message}"
  end

  # Given a line of input, process it.
  # TODO: If an exception is thrown here, the msg might not get logged
  # (but we want to make sure we don't log it twice, either).
  def handle_server_input(s)
    s.chomp!("\n")
    s.chomp!("\r")

    case s
    when /^PING :(.+)$/i
      # Respond to a server ping
      source = Source.new($1)
      message = Message.new(source, nil, 'PING', [ ])
      @callbacks.call('PING', message)

    when /^:(.+?)\s+PRIVMSG\s+(.+?)\s+:?[\001](.+?)(\s+.+)?[\001]$/i
      # CTCP message
      source = Source.new($1)
      dest = $2
      msg = $3.upcase
      arg = $4 ? $4.strip : nil
      message = Message.new(source, dest, msg, [ arg ])
      @ctcp_callbacks.call(msg, message)

    when /^:(.+?)\s+(.+?)\s+(.*)/
      # Server message
      source = Source.new($1)
      msg = $2.upcase
      args = parse_args($3)
      dest = args[0]
      message = Message.new(source, dest, msg, args)
      @callbacks.call(msg, message)
    end
  end

  # Parse a string of arguments of the form "arg1 arg2 :argument 3" and
  # return it as an array of strings.
  def parse_args(str)
    return str.split(/\s+:(.*)|\s+/)
  end
end

