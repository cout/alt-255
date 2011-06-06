require 'alt-255/whatis'
require 'alt-255/proto'

require 'open3'

    def init_commands()
        commands = [
            [ "EVAL",
              "EVAL <expression>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:eval_command),
              -1 ],
            [ "RPNEVAL",
              "RPNEVAL <expression>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:rpneval_command),
              -1 ],
            # [ "RBUNITS",
            #   "RBUNITS <calc>",
            #   IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
            #   method(:units_command),
            #   2 ],
            [ "PROTO",
              "PROTO [section] <name>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:proto_command),
              -1 ],
            [ "WHATIS",
              "WHATIS [section] <name>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:whatis_command),
              -1 ],
            [ "CALC",
              "CALC <calc>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:calc_command),
              -1 ],
            [ "OWNCALC",
              "OWNCALC <calc>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:owncalc_command),
              1 ],
            [ "SEARCHCALC",
              "SEARCHCALC <calc>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:searchcalc_command),
              1 ],
            [ "LISTCALC",
              "LISTCALC <calc>",
              IRC_Bot::PUBLIC_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:listcalc_command),
              1 ],
            [ "OP",
              "OP <channel> <user> <pass>",
              IRC_Bot::PRIVATE_COMMAND,
              method(:op_command),
              3 ],
            [ "CHPASS",
              "CHPASS <user> <oldpass> <newpass>",
              IRC_Bot::PRIVATE_COMMAND,
              method(:chpass_command),
              3 ],
            [ "CHALLENGE",
              "CHALLENGE <arg>",
              IRC_Bot::PRIVATE_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:challenge_command),
              -1 ],
            [ "YOURCHALLENGE",
              "no help available",
              IRC_Bot::PRIVATE_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:yourchallenge_command),
              -1 ],
            [ "CH_OP",
              "CH_OP <challenge_response> <channel>",
              IRC_Bot::PRIVATE_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:ch_op_command),
              2 ],
            [ "HELP",
              "HELP <command>",
              IRC_Bot::PRIVATE_COMMAND | IRC_Bot::LOGGABLE_COMMAND,
              method(:help_command),
              1 ],
        ]

        commands.each do |command|
            add_command(*command)
        end
    end

    # Evaluate an expression and return the result
    def eval_command(user, dest, command, expr)
        # Make sure we have a valid expression (for security reasons), and
        # evaluate it if we do, otherwise return an error message
        begin
            if expr =~ /^[-+*\/\d\seE.()]*$/ then
                expr.untaint
                privmsg(dest, "Result: #{Kernel::eval(expr)}")
            else
                raise "bad input"
            end
       rescue Exception => detail
            log_message detail.message
            privmsg(dest, "Result: Error (#{$!.message})")
       end
    end

    # Evaluate an RPN expression and return the result
    def rpneval_command(user, dest, command, expr)
        begin
            a = Array.new
            expr.untaint
            while expr.length != 0
                case expr
                    when /^([\d.]+[eE]?[\d.]*)(.*)/
                        a.push $1
                    when /^([-+*\/])(.*)/
                        if a.length < 2 then
                            raise RuntimeError, "Not enough arguments"
                        end
                        args = [Kernel::eval(a.pop), Kernel::eval(a.pop)]
                        a.push Kernel::eval("#{args[1]} #{$1} #{args[0]}").to_s
                    else
                        raise RuntimeError, "Syntax error after `#{expr}'"
                end
                expr = $2.strip
            end
            raise RuntimeError, "Stack not empty" if a.length != 1
            privmsg(dest, "Result: #{a.pop}")
        rescue Exception => detail
            privmsg(dest, detail.message)
        end
    end

    def proto_command(user, dest, command, arg_str)
      name, section, proto_str, error_str = nil, nil, nil, nil
      case arg_str
      when /^(\S+)\s*$/ # name
        error_str = "#{$1}: not found"
        name, section, proto_str = proto($1)
      when /^(\S+)\s+(\S+)\s*$/ # section\s+name
        error_str = "#{$2} (#{$1}): not found"
        name, section, proto_str = proto($2, $1)
      else
        send_help(dest, command)
        return
      end
      if name.nil? then
        privmsg(dest, error_str)
      else
        privmsg(dest, "#{name} (#{section}) - #{proto_str}")
      end
    end

    def whatis_command(user, dest, command, arg_str)
      name, section, desc, error_str = nil, nil, nil, nil
      case arg_str
      when /^(\S+)\s*$/ # name
        error_str = "#{$1}: not found"
        name, section, desc = whatis($1)
      when /^(\S+)\s+(\S+)\s*$/ # section\s+name
        error_str = "#{$2} (#{$1}): not found"
        name, section, desc = whatis($2, $1)
      else
        send_help(dest, command)
        return
      end
      if name.nil? then
        privmsg(dest, error_str)
      else
        privmsg(dest, "#{name} (#{section}) - #{desc}")
      end
    end

    # Execute /usr/bin/units with the specified command
    # def units_command(user, dest, command, units_from, units_to)
    #   units_from.untaint; units_to.untaint
    #   input, output, error = Open3.popen3('/usr/bin/units -q --verbose')
    #   input.puts units_from
    #   input.puts units_to
    #   input.close
    #   output.gets; output.gets # eat input
    #   result = "Units says: #{output.gets.strip}" # hmm, this does not work
    #   privmsg(dest, result)
    # end

    # Find a calc
    def calc_command(user, dest, command, expr)
      calc = nil
      case expr
      when /^(\S+)\s+to\s+(\w+)/i
        # Only allow 'to' if the message came from in-channel
        if dest =~ /^#/ then
          calc = $1
          dest = $2
        else
          privmsg(dest, "'to' allowed only within channel")
          return
        end
      when /(\S+)/
        calc = $1
      else
        send_help(dest, command)
        return
      end
      str = @calcdb.calc(calc)
      str = "Calc not found: #{calc}" if not str
      privmsg(dest, str)
    end

    # Determine the user of a calc
    def owncalc_command(user, dest, command, calc)
      owner = @calcdb.owncalc(calc)
      if owner then
        privmsg(dest, "#{calc} is owned by #{owner}")
      else
        privmsg(dest, "Calc not found: #{calc}")
      end
    end

    # Search the calc strings for a calc
    def searchcalc_command(user, dest, command, pattern)
      if pattern =~ /[^\w\d.+*?()\[\]_^$-]/ then
        privmsg(dest, "Invalid pattern")
      else
        begin
          regex = /#{pattern}/i
        rescue SyntaxError, RegexpError
          privmsg(dest, $!)
          return
        end
        result = @calcdb.searchcalc(regex, 25)
        if result.size == 0 then
          privmsg(dest, "No entries found")
        else
          privmsg(dest, result.join(' '))
        end
      end
    end

    # Search the calc keys for a calc
    def listcalc_command(user, dest, command, pattern)
      if pattern =~ /[^\w\d.+*?()\[\]_^$-]/ then
        privmsg(dest, "Invalid pattern")
      else
        begin
          regex = /#{pattern}/i
        rescue SyntaxError, RegexpError
          privmsg(dest, $!)
          return
        end
        result = @calcdb.listcalc(regex, 25)
        if result.size == 0 then
          privmsg(dest, "No entries found")
        else
          privmsg(dest, result.join(' '))
        end
      end
    end

    # Op a user
    def op_command(user, dest, command, channel, username, pass)
        username.untaint
        pass.untaint
        if @userdb.validate_user(username, pass) then
            send "MODE #{channel} +o :#{user.nick}"
        else
            log_message "[ Invalid user or pass ]"
        end
    end

    # Change a user's password
    def chpass_command(user, dest, command, username, oldpass, newpass)
        username.untaint
        oldpass.untaint
        newpass.untaint
        if @userdb.change_pass(username, oldpass, newpass) then
            privmsg(user.nick, "Password changed")
        end
    end

    # Request a challenge
    def challenge_command(user, dest, command, arg)
        botname = "#{user.user}@#{user.host}"
        botname.untaint
        if @botdb.valid_bot(botname) then
            challenge = @botdb.get_challenge(botname)
            privmsg(user.nick, "YOURCHALLENGE #{challenge} #{arg}")
        else
            log_message "[ Unknown bot #{botname} requested challenge ]"
        end
    end

    # Respond to a challenge
    def yourchallenge_command(user, dest, command, arg)
        challenge, msg, msg_arg = arg.split(/\s+/, 3)
        case msg
            when "OP"
                challenge.untaint
                response = @botdb.get_response(@private_key, challenge)
                privmsg(user.nick, "CH_OP #{response} #{msg_arg}")
            else
                log_message "[ Unknown challenge type #{msg} from #{user.nick} ]"
        end
    end

    # Request ops using challenge/response authentication
    def ch_op_command(user, dest, command, response, channel)
        botname = "#{user.user}@#{user.host}"
        botname.untaint
        if @botdb.valid_bot(botname) then
            if @botdb.validate_bot(botname, response) then
                send "MODE #{channel} +o :#{user.nick}"
            else
                log_message "[ Invalid op response from #{botname} ]"
            end
        else
            log_message "[ Unknown user #{botname} requested ops ]"
        end
    end

    # Send help
    def help_command(user, dest, help_command, command_arg)
      send_help(dest, command_arg)
    end

