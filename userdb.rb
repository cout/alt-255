require 'pstore'

#
# A user database that allows users to authenticate via passwords.
#

class UserDB

public
    def initialize(file)
        @userdb = PStore.new(file)
    end

    # Validate a user by making sure he has sent a valid password.
    def validate_user(user, pass)
        return false if !user or !pass
        if $SAFE >= 1 && (user.tainted? || pass.tainted?) then
            raise SecurityError
        end

        begin
            @userdb.transaction do
                return @userdb[user] == pass.crypt(SALT)
            end
        rescue PStore::Error
            return false
        end
    end
    
    # Add a new user
    def add_user(user, pass)
        return false if !user or !pass
        if $SAFE >= 1 && (user.tainted? || pass.tainted?) then
            raise SecurityError
        end

        @userdb.transaction do
            @userdb[user] = pass.crypt(SALT)
            return true
        end
    end

    # Validate a user and change his password
    def change_pass(user, oldpass, newpass)
        return false if !validate_user(user, oldpass)
        if $SAFE >= 1 && (user.tainted? || pass.tainted? || newpass.tainted?)
            raise SecurityError
        end

        begin
            @userdb.transaction do
                crypt = @userdb[user]
                @userdb[user] = pass.crypt(SALT)
                return true
            end
        rescue PStore::Error
            return false
        end
    end

private
    SALT = '42'

end
