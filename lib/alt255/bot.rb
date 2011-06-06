require 'alt255/irc'
require 'alt255/userdb'
require 'alt255/botdb'
require 'alt255/calcdb'

require 'thread'

BOTCMDS_PATH = File.dirname(__FILE__)

# Don't allow use of "tainted" data by potentially dangerous operations
# We'd go up to safe level 2, but then the user database doesn't work, since
# level 2 disallows flock()
$SAFE=1

# An irc bot that uses the IRC interface for communicating (see irc.rb).
# The initialize() function initializes the bots and adds commands to be
# processed.  We also keep track of a user database and a bot database (for
# authentication purposes), and support the EVAL and RPNEVAL commands.
class IRC_Bot < IRC

public

    # -----------------------------------------------------------------------
    # Data structures
    # -----------------------------------------------------------------------
    
    Command = Struct.new("Command",
        :name,
        :help,
        :flags,
        :cb,
        :num_args)

    User = Struct.new("User",
        :nick,
        :user,
        :host)

    PUBLIC_COMMAND   = 1
    PRIVATE_COMMAND  = 2
    LOGGABLE_COMMAND = 4

    # -----------------------------------------------------------------------
    # Initialization
    # -----------------------------------------------------------------------

    def initialize(config)
        super(
            config::SERVER,
            config::PORT,
            config::PING_INTERVAL,
            config::PING_TIMEOUT)

        @user = config::USER
        @real_name = config::REAL_NAME
        @nicks = config::NICKS
        @current_nick = 0
        @channels = config::CHANNELS
        @timestamp = config::TIMESTAMP

        # Initialize our databases
        @userdb = UserDB.new(config::USER_DB)
        @botdb = BotDB.new(config::BOT_DB)
        @calcdb = CalcDB.new(config::CALC_DB)

        # And save the list of bots to authenticate to and our private key (so
        # we can get opped automatically)
        @botlist = config::BOTLIST
        @private_key = config::PRIVATE_KEY

        @commands = Hash.new

        @outgoing_queue = Queue.new
        @outgoing_delay = 0.1 # TODO: make this configurable

        # Register for all the events we will want to receive
        register RPL_WELCOME, method(:welcome_event)
        register ERR_NONICKNAMEGIVEN, method(:badnick_event)
        register ERR_ERRONEUSNICKNAME, method(:badnick_event)
        register ERR_NICKNAMEINUSE, method(:badnick_event)
        register_unknown method(:unknown_message_event)
        register 'PRIVMSG', method(:privmsg_event)
        register 'PING', method(:ping_event)
        register_ctcp 'PING', method(:ctcp_ping_event)
        register_ctcp 'VERSION', method(:ctcp_version_event)
        register_default_ctcp method(:unknown_ctcp_event)

        # Now add a number of commands to be processed when we receive them.
        init_commands()
    end

    # -----------------------------------------------------------------------
    # Main loop
    # -----------------------------------------------------------------------
    
    def run()
        # Run a thread to handle outgoing messages
        outgoing_thread = run_outgoing_thread

        # Connect and log in
        log_message "Connecting to #{@server} on port #{@port}"
        connect()
        log_message "Logging in"
        login(@user, @nicks[@current_nick], @real_name)
        log_message "Complete.  Entering main loop."

        # If we get an exception, we don't want to exit
        catch :done do
            super()
            throw :done
        end
        outgoing_thread.kill
    end

    def shutdown
        @outgoing_thread.kill if @outgoing_thread.alive?
        super
    end

    def run_outgoing_thread
      thread = Thread.new do
        begin
          loop do
            s = @outgoing_queue.shift
            log_message "--> #{s}"
            send_impl(s)
            sleep @outgoing_delay
          end
        rescue Interrupt
          raise Interrupt
        rescue Exception => detail
          puts detail.message
          puts detail.backtrace.join("\n")
        end
      end
    end

    # Override send() so we can print outgoing messages
    def send(s)
      @outgoing_queue.push(s)
    end

    # Override nick() so we can figure out what our nick is changing to
    def nick(str)
        nick_index = @nicks.index(str)
        if !nick_index then
            @current_nick = @nicks.length
            @nicks.push_back(str)
        else
            @current_nick = nick_index
        end
        super(str)
    end

    # Override join() so we can figure out which channel we are joining
    # TODO: This should keep a list of channels
    def join(channel)
        @channel = channel
        super(channel)
    end

    # Override part() so we can figure out which channel we are parting
    # TODO: This should keep a list of channels
    def part(channel)
        if @channel == channel then
            @channel = nil
        end
        super(channel)
    end

    # Add a new command for processing; the specified method is called
    # whenever a privmsg is received that begins with "name"; i.e. a
    # method for a command called "OP" will be called whenever a message
    # "OP mypassword #channel" is received.  The flags argument specifies
    # flags for a command; this includes whether the command is public or
    # private (private commands are only responded to when sent as a
    # privmsg), and whether the command is loggable (non-loggable commands
    # only get the command logged, not the arguments, so specify non-
    # loggable for commands where passwords are sent).  A method should
    # expect the following parameters: 
    #   user - the User the command came from
    #   dest - the destination for the response (the channel name if the
    #          message was sent to a channel, or the user's nick if the
    #          message was sent directly to our nick
    #   cmd  - the full string of the command
    #   args - any number of arguments, as specified by num_args.  Special
    #          value for num_args are -1 (send the arguments as one long
    #          string), and -2 (split the arguments by whitespace and
    #          pass the arguments as an array)
    def add_command(name, help, flags, method, num_args)
        command = Command.new(name.upcase, help, flags, method, num_args)
        @commands[name.upcase] = command
    end


protected

    # -----------------------------------------------------------------------
    # Events
    # -----------------------------------------------------------------------
    
    def welcome_event(source, msg, args)
        log_message "welcome event"
        # Join a channel and request ops
        @channels.each do |channel|
            join(channel)
            @botlist.each do |bot|
                privmsg(bot, "CHALLENGE OP #{channel}")
            end
        end
        return false
    end

    def badnick_event(source, msg, args)
        log_message "[ Received #{msg}; rotating nicks ]"
        @current_nick = (@current_nick + 1) % @nicks.length
        nick(@nicks[@current_nick])
    end

    def ping_event(source, msg, args)
        log_message "[ Server ping ]"
        return super(source, msg, args)
    end

    def ctcp_ping_event(source, dest, msg, arg)
        log_message "[ CTCP PING #{arg} from #{source} ]"
        return super(source, dest, msg, arg)
    end

    def ctcp_version_event(source, dest, msg, arg)
        log_message "[ CTCP VERSION from #{source} ]"
        return super(source, dest, msg, arg)
    end

    def unknown_ctcp_event(source, dest, msg, arg)
        log_message "[ unknown CTCP #{msg} from #{source} ]"
        return true
    end

    def privmsg_event(source, msg, args)
        nick, user, host = parse_source(source)
        return false if !nick
        user = User.new(nick, user, host)

        to = args[0]
        upnick = @nicks[@current_nick].upcase
        upto = to.upcase
        destination = to.upcase == upnick ? nick : upto

        command, command_args = args[1].split(/\s+/, 2)
        cmd = @commands[command.upcase]

        if cmd then
            # If this is a private-only command, then make sure it was sent
            # to us directly, and not to a channel.
            if cmd.flags & PRIVATE_COMMAND != 0 && upto != upnick
                return false
            end

            if cmd.num_args == -1 then
                # If the number of args is -1, then pass it as a string
                log_command(cmd, args[1], user, to)
                cmd.cb.call(user, destination, command, command_args)
                return true
            elsif cmd.num_args == -2
                # If the number of args is -2, then pass it as an array
                arr = command_args ? command_args.split(/\s+/) : []
                log_command(cmd, args[1], user, to)
                cmd.cb.call(user, destination, command, *arr)
                return true
            else
                # Otherwise, pass the argument as a list of strings
                arr = command_args ? command_args.split(/\s+/) : []
                if arr.size != cmd.num_args then
                    # If the user passed the wrong number of arguments, then
                    # offer help
                    send_help(destination, command)
                else
                    log_command(cmd, args[1], user, to)
                    cmd.cb.call(user, destination, command, *arr)
                    return true
                end
            end
        end

        return false
    end

    def unknown_message_event(s)
        log_message s
        return true
    end

    def inspect
      return "<IRC_Bot>"
    end

private

    # -----------------------------------------------------------------------
    # Misc. utility functions
    # -----------------------------------------------------------------------

    # Log a command; if the command does not have the LOGGABLE_COMMAND
    # flag set, then only log the command itself, and not the arguments.
    def log_command(cmd, str, user, to)
        if cmd.flags & LOGGABLE_COMMAND != 0 then
            log_message "[ `#{str}' from " +
                        "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
        else
            log_message "[ `#{cmd.name}' from " +
                        "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
        end
    end

    # Log a message
    def log_message(message)
        timestamp = @timestamp ? "#{Time.now.strftime('%H%M%S')} " : ""
        puts "#{timestamp}#{message}"
    end

    # Send help for a command
    def send_help(destination, command=nil)
        log_message "Sending help to #{destination}"
        if command then
            cmd = @commands[command.upcase]
            if cmd then
                privmsg(destination, "Usage: #{cmd.help}")
            else
                privmsg(destination, "No such command")
            end
        else
            privmsg(destination, @help.keys)
        end
    end

    load File.join(BOTCMDS_PATH, './botcmds.rb')

end

