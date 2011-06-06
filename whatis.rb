# WHATIS_DB = '/usr/share/man/whatis'
WHATIS_DB = '/dev/null'
WHATIS_CACHE = Hash.new

File.open(WHATIS_DB) do |db|
  db.each_line do |line|
    if line =~ /^(\w+)\s+\((\w+)\)\s+-\s+(.*)$/ then
      name = $1
      section = $2
      description = $3
      WHATIS_CACHE[name] ||= Hash.new
      WHATIS_CACHE[name][section] = description
    end
  end
end

def whatis(search_name, search_section=nil)
  whatis_hit = WHATIS_CACHE[search_name]
  return [ nil, nil, nil ] if whatis_hit.nil?
  if search_section.nil? then
    result = whatis_hit.to_a[0]
    return [ search_name, result[0], result[1] ]
  else
    result = whatis_hit[search_section]
    return [ nil, nil, nil ] if result.nil?
    return [ search_name, search_section, result ]
  end
end

if __FILE__ == $0 then
  name, section, description = whatis(ARGV[0], ARGV[1])
  if name.nil? then
    puts "Not found"
  else
    puts "#{name} (#{section}) - #{description}"
  end
end

