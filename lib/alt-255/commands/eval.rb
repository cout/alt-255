class EvalCommand < Command
  NAME = 'eval'
  HELP = 'eval <expression>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    expr = command.str

    # Make sure we have a valid expression (for security reasons), and
    # evaluate it if we do, otherwise return an error message
    begin
      if expr =~ /^[-+*\/\d\seE.()]*$/ then
        expr.untaint
        command.reply("Result: #{Kernel::eval(expr)}")
      else
        raise "bad input"
      end
     rescue Exception => detail
       command.log(detail.message)
       command.reply("Result: Error (#{$!.message})")
    end
  end
end
