PROTO_DATA_FILE = 'proto.dat'
PROTO_CACHE = Hash.new

File.open(PROTO_DATA_FILE) do |db|
  db.each_line do |line|
    name, section, proto_str = line.chomp.split(':', 3)
    PROTO_CACHE[name] ||= Hash.new
    PROTO_CACHE[name][section] = proto_str
  end
end
def proto(search_name, search_section=nil)
  proto_hit = PROTO_CACHE[search_name]
  return [ nil, nil, nil ] if proto_hit.nil?
  if search_section.nil? then
    result = proto_hit.to_a[0]
    return [ search_name, result[0], result[1] ]
  else
    result = proto_hit[search_section]
    return [ nil, nil, nil ] if result.nil?
    return [ search_name, search_section, result ]
  end
end


