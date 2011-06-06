require './rsa.so'

pubkey =
"-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAL6LDqt08FBHPzDZ6VfDquAumR91vC8U
WrzSE6KhWhP335dnVvFH3OqXwcXXShpLWGMt3VXs1Ee7/tW3c0GzxXECAwEAAQ==
-----END PUBLIC KEY-----"

privkey =
"-----BEGIN RSA PRIVATE KEY-----
MIIBOwIBAAJBAL6LDqt08FBHPzDZ6VfDquAumR91vC8UWrzSE6KhWhP335dnVvFH
3OqXwcXXShpLWGMt3VXs1Ee7/tW3c0GzxXECAwEAAQJBALwou6LKxmiwApGuDoQx
X7MjsOflLqDbG8NsPCGT7kzZ+jNMdiG0yaEQg6+NNECR/6oJeTopfCGathYz+7o5
OrECIQD08iXW5OrMd7h1udvhnkeaJrF2zOrr3CobHPz+iI1yNQIhAMckZZcT3ypV
1kNlPRG+vffGh+YOVsCP930RZxMJbC3NAiEAjnlq2Rw+FsBsYs3Av/M44sku4FNB
Mf/V3f92iPcUjyECIDewVvR7qyG0pVltezl2JLugeip8gggRen0wG6n4LZdVAiBK
a7LanBPnoDqqvBQpcleottKljJTboNZXGjo0BeTDNA==
-----END RSA PRIVATE KEY-----"

puts "---"
encstr1 = RSA::encrypt(pubkey, RSA::PUBLIC_KEY, "This is a test")
encstr = [encstr1].pack('m').gsub("\n", "")
puts encstr

puts "---"
decstr1 = encstr.unpack('m')[0]
decstr = RSA::decrypt(privkey, RSA::PRIVATE_KEY, decstr1)
puts decstr
