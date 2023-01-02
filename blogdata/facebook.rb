#!/usr/bin/ruby

# This was a quick hack to download Facebook URLs from 
# http://www.facebook.com/directory
#
# @author Ron Bowes
# @date 2010-07-11

require 'net/http'
require 'uri'

File.open("input.txt", "r") do |infile|
	while (path = infile.gets) do
		if(path =~ /directory/) then
			attempts = 0
			while true do
				begin
					count = 0
					$stderr.puts("PATH: " + path)
					url = URI.parse(path)
					res = Net::HTTP.start(url.host, url.port) {|http|
						http.get(url.path, {"User-agent"=>"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"})
					}
					links = res.body.scan(/UIDirectoryBox_Item.*?a href="(.*?)"/)
				
					links.each { |link|
						link = link.shift
						puts link
						count = count + 1
					}
					$stderr.puts("Found %d links!" % count)

					if(count == 0) then
						attempts = attempts + 1
						if(attempts > 3)
							$stderr.puts("Giving up!")
							break
						else
							$stderr.puts("Found no links, trying again (%d retries left)!" % (3 - attempts))
						end
						sleep(10)
					else
						break
					end
				rescue Exception
					$stderr.puts("ERROR: " + $!)
					sleep(30)
				end
			end
		else
			$stderr.puts("Skipping: " + path)
			puts(path)
		end
	end
end




