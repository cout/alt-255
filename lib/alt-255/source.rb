class Source
  attr_reader :nick
  attr_reader :user
  attr_reader :host

  def initialize(str)
    if /(.+?)!(.+?)@(.+)/ =~ str then
        @nick, @user, @host = $1, $2, $3
    else
        @nick, @user, @host = nil, nil, str
    end
  end
end

