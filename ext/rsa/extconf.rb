require 'mkmf'
have_library('crypto')
create_makefile('rsa_ext')
system('echo LDFLAGS+=-lcrypto >> Makefile')
system('echo CFLAGS+=-Wall -g >> Makefile')
