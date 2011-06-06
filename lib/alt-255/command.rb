class Command
  def initialize(bot)
    @bot = bot
  end

  @commands = [ ]

  def public?
    return self.class::PUBLIC
  end

  def loggable?
    return self.class::LOGGABLE
  end

  class << self
    attr_reader :commands

    def inherited(klass)
      @commands << klass
    end
  end
end

