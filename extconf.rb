require 'mkmf'
have_library('crypto')
create_makefile('rsa')
system('echo LDFLAGS+=-lcrypto >> Makefile')
system('echo CFLAGS+=-Wall -g >> Makefile')
