require 'alt-255/whatis'

class WhatisCommand < Command
  NAME = 'whatis'
  HELP = 'whatis [section] <name>'
  PUBLIC = true
  LOGGABLE = true

  def whatis_command(command)
    name, section, desc, error_str = nil, nil, nil, nil

    case command.str
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
      command.reply(error_str)
    else
      command.reply("#{name} (#{section}) - #{desc}")
    end
  end
end
