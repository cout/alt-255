class Command
  def initialize(bot)
    @bot = bot
  end

  @commands = [ ]

  class << self
    attr_reader :commands

    def inherited(klass)
      @commands << klass
    end
  end
end

