class Plugin
  def self.load(bot, filename)
    str = File.read(filename)
    m = Module.new
    m.module_eval(str.untaint, filename)

    plugins = [ ]

    m.constants.each do |const|
      c = m.const_get(const)
      if c < Plugin then
        plugins << c.new(bot)
      end
    end

    return plugins
  end
end
