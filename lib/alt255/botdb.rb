require 'alt255/rsa'

require 'pstore'

#
# A bot database that keeps track of bots and allows them to authenticate
# via RSA public-key encryption (uses openssl)
#

class BotDB

    BotEntry = Struct.new("BotEntry", :name, :challenge, :public_key)

    def initialize(file)
        @botdb = PStore.new(file)
    end

    # Validate a bot
    def validate_bot(bot, response)
        return false if !bot
        if $SAFE >= 1 && bot.tainted? then
            raise SecurityError
        end

        bot = bot.upcase

        begin
            public_key = nil
            challenge = nil

            @botdb.transaction do
                bot_entry = @botdb[bot]
                challenge = bot_entry.challenge
                public_key = bot_entry.public_key
                bot_entry.challenge = nil
                @botdb[bot] = bot_entry
            end

            return false if !challenge
            decstr = RSA::decrypt(
                public_key,
                RSA::PUBLIC_KEY,
                response.unpack('m')[0])
            return decstr == challenge
            
        rescue PStore::Error
            return false
        end
    end

    # Get a new challenge
    def get_challenge(bot)
        return false if !bot
        if $SAFE >= 1 && bot.tainted? then
            raise SecurityError
        end

        bot = bot.upcase

        begin
            @botdb.transaction do
                bot_entry = @botdb[bot]
                bot_entry.challenge = ""
                20.times do
                    bot_entry.challenge << rand(64) + ?A - 2
                end
                @botdb[bot] = bot_entry
                return bot_entry.challenge
            end

        rescue PStore::Error
            return false
        end
    end

    # Given a challenge and a private key, get a response
    def get_response(key, challenge)
        return false if !key or !challenge
        if $SAFE >= 1 && (key.tainted? || challenge.tainted?) then
            raise SecurityError
        end

        encstr = RSA::encrypt(key, RSA::PRIVATE_KEY, challenge)
        return [encstr].pack('m').gsub("\n", "")
    end
    
    # Determine whether the bot is in our database
    def valid_bot(bot)
        return false if !bot
        if $SAFE >= 1 && bot.tainted? then
            raise SecurityError
        end

        bot = bot.upcase

        begin
            @botdb.transaction do
                bot_entry = @botdb[bot]
                return true
            end
        rescue PStore::Error
            return false
        end
    end

    # Add a new bot to the database.
    def add_bot(bot, key)
        return false if !bot or !key
        if $SAFE >= 1 && (bot.tainted? || key.tainted?) then
            raise SecurityError
        end

        bot = bot.upcase

        @botdb.transaction do
            bot_entry = BotEntry.new(bot, nil, key)
            @botdb[bot] = bot_entry
            return true
        end
    end

end
