require 'alt-255/rfc2812'
require 'alt-255/message'
require 'alt-255/source'

require 'socket'

# The irc class, which talks to the server and holds the main event loop.
# Through this class, a client can register for events and respond to them.
class IRC

    include RFC2812

public

    def initialize(server, port, ping_interval = 300, ping_timeout = 600)
        @server = server
        @port = port

        @callbacks = Hash.new { |h,k| h[k] = [ ] }
        @ctcp_callbacks = Hash.new { |h,k| h[k] = [ ] }

        @ping_interval = ping_interval
        @ping_timeout = ping_timeout

        register 'PING', method(:ping_event)
        register_ctcp 'PING', method(:ctcp_ping_event)
        register_ctcp 'VERSION', method(:ctcp_version_event)
    end

    attr_reader :server, :port

    # Callback type          Arguments
    # -------------          ---------
    # server message         source:String, msg:String, args:Array
    # unhandled message      source:String, msg:String, args:Array
    # ctcp message           source:String, dest:String, msg:String, arg:String
    # unhandled ctcp message source:String, dest:String, msg:String, arg:String
    # unknown message        message:String

    # Register for a server message.  The msg argument can be either a
    # string (for string server messages) or a number (for numeric
    # server messages).
    def register(msg, callback)
        key = msg.kind_of?(Numeric) \
          ? ("%03d" % msg)          \
          : msg.to_s.upcase
        @callbacks[key] ||= [ ]
        @callbacks[key] << callback
    end

    # Set the default callback for unhandled messages (server messages for
    # which there is no registered callback).
    def register_default(callback)
      @callbacks.default ||= [ ]
      @callbacks.default << callback
    end

    # Register for a server message.  The msg argument can be either a
    # string (for string server messages) or a number (for numeric
    # server messages).
    def register_ctcp(msg, callback)
      @ctcp_callbacks[msg.to_s.upcase] ||= [ ]
      @ctcp_callbacks[msg.to_s.upcase] << callback
    end

    # Set the default callback for unhandled messages (server messages for
    # which there is no registered callback).
    def register_default_ctcp(callback)
      @ctcp_callbacks.default ||= [ ]
      @ctcp_callbacks.default << callback
    end

    # Connect to the IRC server
    def connect()
        @irc = TCPSocket.open(@server, @port)
    end

    # Log in to the IRC server
    def login(user, nick, real_name, flags=8)
        send "USER #{user} #{flags} * :#{real_name}"
        send "NICK #{nick}"
    end

    # Just keep on truckin' until we disconnect
    def run()
        mutex = Mutex.new

        @stdin_thread = Thread.new do
            Thread.current.abort_on_exception = true
            puts "starting stdin thread"
            loop do
                s = $stdin.gets
                mutex.synchronize do
                    handle_console_input(s)
                end
            end
        end

        last_message = Time.now
        @sock_thread = Thread.new do
            Thread.current.abort_on_exception = true
            puts "starting sock thread"
            loop do
                s = @irc.gets
                last_message = Time.now
                break if s.nil?
                mutex.synchronize do
                    handle_server_input(s)
                end
            end
        end

        @ping_thread = Thread.new do
            Thread.current.abort_on_exception = true
            puts "starting ping thread"
            loop do
                mutex.synchronize do
                    send "PING :localhost"
                end
                GC.start
                sleep @ping_interval
            end
        end

        while @stdin_thread.alive? and
              @sock_thread.alive? and
              @ping_thread.alive? and
              Time.now - last_message < @ping_timeout do
          sleep 1
        end

        # TODO: Should I try to let the threads shut down cleanly?
        shutdown
    end

    def shutdown
        puts "shutting down"
        @stdin_thread.kill if @stdin_thread and @stdin_thread.alive?
        @sock_thread.kill if @sock_thread and @sock_thread.alive?
        @ping_thread.kill if @ping_thread and @ping_thread.alive?
    end

    # Change the current nick
    def nick(str)
        send("NICK #{str}")
    end

    # Send a message to the irc server and print it to the screen
    def send_impl(s)
        @irc.send "#{s}\n", 0 
    end
    alias_method :send, :send_impl

    # Send a message to a user or a channel
    def privmsg(destination, s)
        send "PRIVMSG #{destination} :#{s}"
    end
    
    # Join a channel
    def join(channel)
        send "JOIN #{channel}"
    end

    # Leave a channel
    def part(channel)
        send "PART #{channel}"
    end

    # Change the topic on a channel
    def topic(channel, str)
        send "TOPIC #{channel} :#{str}"
    end

    # Respond to a ping request
    def reply_ping(user, str)
        send "NOTICE #{user} :\001PING #{str}\001"
    end

    # Respond to a version request
    def reply_version(user, version)
        send "NOTICE #{user} :\001#{version}\001"
    end

    # Quit with a message
    def quit(message="")
        send "QUIT :#{message}"
    end

protected

    # Given a line typed at the console, process it
    def handle_console_input(s)
      case s
      when /\/(.*?)\s+(.*)/i
        cmd = $1
        args = $2
        case cmd
        when /eval/i
          eval(args.untaint)
        else
          puts "Invalid command: #{cmd}"
        end 
      else
        send(s)
      end
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
                @callbacks['PING'].each { |cb| cb.call(message) }

            when /:(.+?) PONG (.+?) :(.+)/
                source = Source.new($1)
                message = Message.new(source, nil, 'PONG', [ ])
                @callbacks['PONG'].each { |cb| cb.call(message) }

            when /^:(.+?)\s+PRIVMSG\s+(.+?)\s+:?[\001](.+?)(\s+.+)?[\001]$/i
                # CTCP message
                source = Source.new($1)
                dest = $2
                msg = $3.upcase
                arg = $4 ? $4.strip : nil
                message = Message.new(source, dest, msg, [ arg ])
                @ctcp_callbacks[msg].each { |cb| cb.call(message) }

            when /^:(.+?)\s+(.+?)\s+(.*)/
                # Server message
                source = Source.new($1)
                msg = $2.upcase
                args = parse_args($3)
                dest = args[0]
                message = Message.new(source, dest, msg, args)
                @callbacks[msg].each { |cb| cb.call(message) }
        end
    end

    # Handle a server PING
    def ping_event(message)
        send "PONG :#{message.source}"
    end

    # Handle a CTCP PING
    def ctcp_ping_event(message)
      reply_ping(message.source.nick, message.args[0]) unless !message.source.nick
    end

    # Handle a CTCP VERSION
    def ctcp_version_event(message)
      reply_version(message.source.nick, @version_string) unless !message.source.nick
    end

    # Parse a string of arguments of the form "arg1 arg2 :argument 3" and
    # return it as an array of strings.
    def parse_args(str)
        return str.split(/\s+:(.*)|\s+/)
    end
end

