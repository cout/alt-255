class Source
  attr_reader :str
  attr_reader :nick
  attr_reader :user
  attr_reader :host

  def initialize(str)
    @str = str

    if /(.+?)!(.+?)@(.+)/ =~ str then
        @nick, @user, @host = $1, $2, $3
    else
        @nick, @user, @host = nil, nil, str
    end
  end

  def to_s
    return @str
  end
end

