require 'userdb'

userdb = UserDB.new("users.db")
userdb.add_user(ARGV[0], ARGV[1])
