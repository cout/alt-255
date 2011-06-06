require 'alt-255/proto'

class ProtoCommand < Command
  NAME = 'proto'
  HELP = 'proto [section] <name>'
  PUBLIC = true
  LOGGABLE = true

  def do(command)
    name, section, proto_str, error_str = nil, nil, nil, nil

    case command.str
    when /^(\S+)\s*$/ # name
      error_str = "#{$1}: not found"
      name, section, proto_str = proto($1)
    when /^(\S+)\s+(\S+)\s*$/ # section\s+name
      error_str = "#{$2} (#{$1}): not found"
      name, section, proto_str = proto($2, $1)
    else
      command.send_help()
      return
    end

    if name.nil? then
      command.reply(error_str)
    else
      command.reply("#{name} (#{section}) - #{proto_str}")
    end
  end
end
