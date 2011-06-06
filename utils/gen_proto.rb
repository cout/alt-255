WHATIS_FILE = '/usr/share/man/whatis'
SECTIONS = [ '2', '3' ]

# This script takes a LONG time to run.  It is hardly optimal.
#
def unformat(line)
  return line.gsub(/.\010/, '')
end

def find_proto(name, section)
  IO.popen("man #{section} #{name} 2>&1", "r") do |man|
    synopsis = false
    man.each_line do |line|
      case unformat(line)
      when /^SYNOPSIS/
        synopsis = true
      when /^DESCRIPTION/
        synopsis = false
      when /^\s*(.*#{name}\s*\(.*\))/
        return $1 if synopsis
      end
    end
  end
  return nil
end

File.open(WHATIS_FILE).each do |whatis|
  whatis.each_line do |line|
    if line =~ /^(\w+)\s+\((\w+)\)\s+-\s+(.*)$/ then
      name = $1
      section = $2
      description = $3
      if SECTIONS.include?(section) then
        result = find_proto(name, section)
        if result then
          puts "#{name}:#{section}:#{result}"
        end
      end
    end
  end
end

