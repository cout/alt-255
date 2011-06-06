require 'open3'

class UnitsCommand < Command
  NAME = 'units'
  HELP = 'units <arg>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    # Execute /usr/bin/units with the specified command
    # units_from.untaint; units_to.untaint
    # input, output, error = Open3.popen3('/usr/bin/units -q --verbose')
    # input.puts units_from
    # input.puts units_to
    # input.close
    # output.gets; output.gets # eat input
    # result = "Units says: #{output.gets.strip}" # hmm, this does not work
    # privmsg(dest, result)
  end
end
