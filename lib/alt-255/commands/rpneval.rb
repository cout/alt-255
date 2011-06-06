class RpnEvalCommand < Command
  NAME = 'rpneval'
  HELP = 'rpneval <expression>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    expr = command.str

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
      command.reply("Result: #{a.pop}")
    rescue Exception => detail
      command.reply(detail.message)
    end
  end
end

