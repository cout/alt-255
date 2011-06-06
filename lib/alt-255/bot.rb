require 'alt-255/irc'
require 'alt-255/userdb'
require 'alt-255/botdb'
require 'alt-255/calcdb'
require 'alt-255/command'
require 'alt-255/command_args'
require 'alt-255/commands'

require 'thread'

# Don't allow use of "tainted" data by potentially dangerous operations
# We'd go up to safe level 2, but then the user database doesn't work, since
# level 2 disallows flock()
$SAFE=1

# An irc bot that uses the IRC interface for communicating (see irc.rb).
# The initialize() function initializes the bots and adds commands to be
# processed.  We also keep track of a user database and a bot database (for
# authentication purposes), and support the EVAL and RPNEVAL commands.
class IRC_Bot < IRC
  attr_reader :botdb
  attr_reader :userdb

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

    # TODO: register new commands at run-time as well
    @commands = { }
    Command.commands.each do |klass|
      @commands[klass::NAME.upcase] = klass.new(self)
    end

    @outgoing_queue = Queue.new
    @outgoing_delay = 0.1 # TODO: make this configurable

    # Register for all the events we will want to receive
    register RPL_WELCOME, method(:welcome_event)
    register ERR_NONICKNAMEGIVEN, method(:badnick_event)
    register ERR_ERRONEUSNICKNAME, method(:badnick_event)
    register ERR_NICKNAMEINUSE, method(:badnick_event)
    register 'PRIVMSG', method(:privmsg_event)
    register_default_ctcp method(:unknown_ctcp_event)
  end

  # -----------------------------------------------------------------------
  # Main loop
  # -----------------------------------------------------------------------

  def run()
    # Run a thread to handle outgoing messages
    outgoing_thread = run_outgoing_thread

    # Connect and log in
    log "Connecting to #{@server} on port #{@port}"
    connect()
    log "Logging in"
    login(@user, @nicks[@current_nick], @real_name)
    log "Complete.  Entering main loop."

    # TODO: If we get an exception, we don't want to exit
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
          log "--> #{s}"
          send_impl(s)
          sleep @outgoing_delay
        end
      rescue Interrupt
        raise Interrupt
      rescue Exception => detail
        puts "Outgoing thread got an exception"
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
  #   source - the Source the command came from
  #   dest   - the destination for the response (the channel name if the
  #            message was sent to a channel, or the user's nick if the
  #            message was sent directly to our nick
  #   cmd    - the full string of the command
  #   args   - any number of arguments, as specified by num_args.  Special
  #            value for num_args are -1 (send the arguments as one long
  #            string), and -2 (split the arguments by whitespace and
  #            pass the arguments as an array)
  def add_command(name, help, flags, method, num_args)
    command = Command.new(name.upcase, help, flags, method, num_args)
    @commands[name.upcase] = command
  end


  protected

  # -----------------------------------------------------------------------
  # Events
  # -----------------------------------------------------------------------

  def welcome_event(message)
    log "welcome event"
    # Join a channel and request ops
    @channels.each do |channel|
      join(channel)
      @botlist.each do |bot|
        privmsg(bot, "CHALLENGE OP #{channel}")
      end
    end
    return false
  end

  def badnick_event(message)
    log "[ Bad nick; rotating nicks ]"
    @current_nick = (@current_nick + 1) % @nicks.length
    nick(@nicks[@current_nick])
  end

  def ping_event(message)
    log "[ Server ping ]"
    return super(message)
  end

  def ctcp_ping_event(message)
    log "[ CTCP PING #{message.args} from #{message.source} ]"
    return super(message)
  end

  def ctcp_version_event(message)
    log "[ CTCP VERSION from #{message.source} ]"
    return super(message)
  end

  def unknown_ctcp_event(message)
    log "[ unknown CTCP #{message.msg} from #{message.source} ]"
    return true
  end

  def privmsg_event(message)
    return false if !message.source.nick

    if @nicks[@current_nick].upcase == message.dest.upcase then
      reply_to = message.source.nick
      public_message = false
    else
      reply_to = message.dest
      public_message = true
    end

    command, command_args = message.args[1].split(/\s+/, 2)
    cmd = @commands[command.upcase]

    if cmd then
      # If this is a private-only command, then make sure it was sent to
      # us directly and not to a channel.
      return if cmd::PUBLIC and not public_message

      args = CommandArgs.new(self, message, reply_to, command_args)
      cmd.do(args)
    end
  end

  def handle_server_input(s)
    log s
    super(s)
  end

  def inspect
    return "<IRC_Bot>"
  end

  # -----------------------------------------------------------------------
  # Misc. utility functions
  # -----------------------------------------------------------------------

  # Log a command; if the command does not have the LOGGABLE_COMMAND
  # flag set, then only log the command itself, and not the arguments.
  def log_command(cmd, str, user, to)
    if cmd.flags & LOGGABLE_COMMAND != 0 then
      log "[ `#{str}' from " +
      "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
    else
      log "[ `#{cmd.name}' from " +
      "#{user.nick}!#{user.user}@#{user.host} to #{to} ]"
    end
  end

  # Log a message
  def log(message)
    timestamp = @timestamp ? "#{Time.now.strftime('%H%M%S')} " : ""
    puts "#{timestamp}#{message}"
  end

  # Send help for a command
  def send_help(destination, command=nil)
    log "Sending help to #{destination}"
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
end

