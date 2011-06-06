class Plugin
  def self.load(filename)
    str = File.read(plugin)
    m = Module.new
    m.module_eval(str, plugin)

    plugins = [ ]

    m.constants.each do |const|
      c = const.const_get(m)
      if c.is_a?(Plugin) then
        @plugins << c.new(self)
      end
    end

    return plugins
  end
end
