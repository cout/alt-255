dir = File.dirname(__FILE__)
Dir["#{dir}/commands/*.rb"].each do |cmd|
  load cmd.untaint
end

