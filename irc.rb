require 'socket'
require './rfc2812.rb'

# The irc class, which talks to the server and holds the main event loop.
# Through this class, a client can register for events and respond to them.
class IRC

    include RFC2812

public

    def initialize(server, port, ping_interval = 300, ping_timeout = 600)
        @server = server
        @port = port
        @callbacks = Hash.new
        @ctcp_callbacks = Hash.new
        @unknown_callback = nil
        @ping_interval = ping_interval
        @ping_timeout = ping_timeout

        register_ctcp 'PING', method(:ctcp_ping_event)
        register_ctcp 'VERISON', method(:ctcp_version_event)
    end

    attr_reader :server, :port

    # NOTE: All callbacks should return either true or false, depending on
    # whether the message was processed.  This way, event handlers can be
    # chained together, and a message can be printed to the screen if the
    # event was not handled.
    #
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
        old_callback = @callbacks[key]
        @callbacks[key] = callback
        return old_callback
    end

    # Set the default callback for unhandled messages (server messages for
    # which there is no registered callback).
    def register_default(callback)
        old_callback = @callbacks.default
        @callbacks.default = callback
        return old_callback
    end

    # Register for a server message.  The msg argument can be either a
    # string (for string server messages) or a number (for numeric
    # server messages).
    def register_ctcp(msg, callback)
        old_callback = @ctcp_callbacks[msg.to_s.upcase]
        @ctcp_callbacks[msg.to_s.upcase] = callback
        return old_callback
    end

    # Set the default callback for unhandled messages (server messages for
    # which there is no registered callback).
    def register_default_ctcp(callback)
        old_callback = @ctcp_callbacks.default
        @ctcp_callbacks.default = callback
        return old_callback
    end

    # Set the callback for messages that don't match a known pattern.
    def register_unknown(callback)
        old_callback = @unknown_callback
        @unknown_callback = callback
        return old_callback
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
        @stdin_thread.kill if @stdin_thread.alive?
        @sock_thread.kill if @stdin_thread.alive?
        @ping_thread.kill if @ping_thread.alive?
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
        match = false

        s.chomp!("\n")
        s.chomp!("\r")

        case s
            when /^PING :(.+)$/i
                # Respond to a server ping
                if (cb = @callbacks['PING']) then
                    cb.call($1, 'PING', [])
                end
                match = true

            when /:(.+?) PONG (.+?) :(.+)/
                match = true

            when /^:(.+?)\s+PRIVMSG\s+(.+?)\s+:?[\001](.+?)(\s+.+)?[\001]$/i
                # CTCP message
                source = $1
                dest = $2
                msg = $3.upcase
                arg = $4 ? nil : $4.strip
                if (cb = @ctcp_callbacks[msg]) then
                    match = cb.call(source, dest, msg, arg)
                end

            when /^:(.+?)\s+(.+?)\s+(.*)/
                # Server message
                source = $1
                msg = $2.upcase
                args = parse_args($3)
                if (cb = @callbacks[msg]) then
                    match = cb.call(source, msg, args)
                end
        end

        if !match and @unknown_callback then
            @unknown_callback.call(s)
        end
    end

    # Handle a server PING
    def ping_event(source, msg, args)
        send "PONG :#{source}"
    end

    # Handle a CTCP PING
    def ctcp_ping_event(source, dest, msg, arg)
        nick, user, host = parse_source(source)
        reply_ping(nick, arg) unless !nick
    end

    # Handle a CTCP VERSION
    def ctcp_version_event(source, dest, msg, arg)
        nick, user, host = parse_source(source)
        reply_version(nick, @version_string) unless !nick
    end

    # Parse a source string and return nick, user, host.  Returns a nil
    # nick and user if the source string specifies a server.
    def parse_source(source)
        if /(.+?)!(.+?)@(.+)/ =~ source then
            return $1, $2, $3
        else
            return nil, nil, source
        end
    end

    # Parse a string of arguments of the form "arg1 arg2 :argument 3" and
    # return it as an array of strings.
    def parse_args(str)
        return str.split(/\s+:(.*)|\s+/)
    end
end

