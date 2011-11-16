require 'open3'

class UnitsCommand < Command
  NAME = 'units'
  HELP = 'units <arg>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    case command.str
    when  /(.*?)\s+to\s+(.*)/i
      units_from = $1
      units_to = $2
    else
      a = command.str.split
      units_from = a[0..-2].join(' ')
      units_to = a[-1]
    end

    # Execute /usr/bin/units with the specified command
    units_from.untaint; units_to.untaint
    input, output, error = Open3.popen3('/usr/bin/units -q --verbose')
    begin
      input.puts units_from
      input.puts units_to
      output.gets; output.gets # eat input
      command.reply("Units says: #{output.gets.strip}")
    ensure
      input.close
      output.close
    end
  end
end
