class Callbacks
  def initialize
    @h = { }
    @h.default = [ ]
  end

  def add(key, cb)
    list = @h.fetch(key) { @h[key] = [ ] }
    list << cb
  end

  def add_default(cb)
    list = (@h.default ||= [ ])
    list << cb
  end

  def call(key, *msg, &block)
    @h[key].each { |cb| cb.call(*msg, &block) }
  end
end
