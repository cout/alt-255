require 'alt-255/irc'
require 'alt-255/userdb'
require 'alt-255/botdb'
require 'alt-255/calcdb'
require 'alt-255/delayed_output'
require 'alt-255/plugin'

require 'thread'

# Don't allow use of "tainted" data by potentially dangerous operations
# We'd go up to safe level 2, but then the user database doesn't work, since
# level 2 disallows flock()
$SAFE=1

# An irc bot that uses the IRC interface for communicating (see irc.rb).
class IRC_Bot < IRC
  attr_accessor :login_nick

  attr_reader :config
  attr_reader :calcdb
  attr_reader :botdb
  attr_reader :userdb

  def initialize(config)
    super(
        config::SERVER,
        config::PORT)

    @config = config

    @user = config::USER
    @real_name = config::REAL_NAME
    @timestamp = config::TIMESTAMP

    @login_nick = config::NICKS[0]
    @nick = config::NICKS[0]

    # Initialize our databases
    @userdb = UserDB.new(config::USER_DB)
    @botdb = BotDB.new(config::BOT_DB)
    @calcdb = CalcDB.new(config::CALC_DB)

    # And save the list of bots to authenticate to and our private key (so
    # we can get opped automatically)
    @botlist = config::BOTLIST
    @private_key = config::PRIVATE_KEY

    @delayed_output = DelayedOutput.new(self, config::DELAY)

    @plugins = [ ]

    dir = File.dirname(__FILE__)
    plugin_dir = File.join(dir, 'plugins')
    load_plugins(plugin_dir)
  end

  def load_plugins(plugin_dir)
    Dir["#{plugin_dir}/*.rb"].each do |plugin|
      log "Loading plugin #{plugin}"
      @plugins.concat(Plugin.load(self, plugin.untaint))
    end
  end

  # -----------------------------------------------------------------------
  # Main loop
  # -----------------------------------------------------------------------

  def run()
    # Run a thread to handle outgoing messages
    outgoing_thread = @delayed_output.run

    # Connect and log in
    log "Connecting to #{@server} on port #{@port}"
    connect()
    log "Logging in"
    login(@user, @login_nick, @real_name)
    log "Complete.  Entering main loop."

    loop do
      begin
        super()
      rescue Interrupt
        raise Interrupt
      rescue Exception => detail
        puts "Main thread got an exception"
        puts detail.message
        puts detail.backtrace.join("\n")
      end
    end

    outgoing_thread.kill
  end

  def shutdown
    @outgoing_thread.kill if @outgoing_thread.alive?
    super
  end

  # Override sendmsg() so we can print outgoing messages
  def sendmsg(s)
    @delayed_output.push(s)
  end

  def handle_server_input(s)
    log s
    super(s)
  end

  # Log a message
  def log(message)
    timestamp = @timestamp ? "#{Time.now.strftime('%H%M%S')} " : ""
    puts "#{timestamp}#{message}"
  end
end

