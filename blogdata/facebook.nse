description = [[
Spider Facebook's 'directory' service and download people's names. 

This script, by design, requires significant intervention by the user. 
It isn't intended as an automated script by any stretch. User beware!
]]

author = "Ron"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {}

require 'http'
require 'nsedebug'

hostrule = function()
	return true
end

action = function(host, port)
	-- Parse arguments
	local infilename = nmap.registry.args['infilename']

	-- There are two types of outputs -- person and directory. The person file
	-- gets a CVS list written to it (url,name), whereas the directory file 
	-- gets a list of URLs that still have to be checked. 
	local outfilename_names    = nmap.registry.args['outfilename_names']
	local outfilename_directory = nmap.registry.args['outfilename_directory']

	if(not(infilename)) then
		return "ERROR: the 'infilename' argument is required!"
	end
	if(not(outfilename_names)) then
		return "ERROR: the 'outfilename_names' argument is required!"
	end
	if(not(outfilename_directory)) then
		return "ERROR: the 'outfilename_directory' argument is required!"
	end

	-- Open the input file for reading
	local infile = io.open(infilename, "r")
	if(not(infile)) then
		return string.format("ERROR: couldn't open file for reading", infilename)
	end

	-- Open the output files for writing
	local outfile_names = io.open(outfilename_names, 'a')
	if(not(outfile_names)) then
		return string.format("ERROR: couldn't open file %s for writing", outfilename_names)
	end
	local outfile_directory = io.open(outfilename_directory, 'a')
	if(not(outfile_directory)) then
		return string.format("ERROR: couldn't open file %s for writing", outfilename_directory)
	end

	while true do
		local line = infile:read("*line")
		if(not(line)) then
			break
		end

		-- Make sure it's a valid URL
		if(string.find(line, "http")) then
			-- Prepare to receive the body
			local body = nil

			-- Download the page, using multiple attempts if necessary
			local attempts = 0
			repeat
				-- Unless there is our first try, delay
				if(attempts > 0) then
					stdnse.print_debug(1, "Waiting before next attempt...")
					stdnse.sleep(5)
				end

				-- Keep track of number of attempts
				attempts = attempts + 1
				-- Try to download the page
				stdnse.print_debug(1, "Downloading: %s (attempt #%d)", line, attempts)
				local result = http.get_url(line, {header={"User-agent: Googlebot/2.1 (+http://www.google.com/bot.html)"}})
				if(result) then
					body = result.body
				end
			until((body and string.find(body, "UIDirectoryBox_Item")) or attempts > 4)

			-- Print an error if we ran out of attempts
			if(attempts > 4) then
				stdnse.print_debug(1, "ERROR: giving up on path: " .. line)
			else
				-- Now the fun part -- parse out the names + URLs
				-- Each line for a directory looks like this:
				-- <li class="UIDirectoryBox_Item"><a href="http://www.facebook.com/directory/people/A-1211005-1311921">Francie Adams - Tangee Adams</a></li>
				-- And each line for a person looks like this:
				-- <li class="UIDirectoryBox_Item"><a href="http://en-us.facebook.com/people/Khalid-Almahmod/1043203925">Khalid Almahmod</a></li>
				local start, finish, url, name
				finish = 0
				local found = 0

				while true do
					start, finish, url, name = string.find(body, 'UIDirectoryBox_Item.-(http.-)">(.-)<', finish)
					if(not(start)) then
						break
					end

					-- Keep track of how many we found
					found = found + 1

					-- Check if it's a directory or a name
					if(string.find(url, "directory")) then
						outfile_directory:write(string.format("%s\n", url))
--						io.write("Directory: " .. url .. "\n")
					else
						outfile_names:write(string.format("%s,%s\n", url, name))
--						io.write("Name: " .. url .. "\n")
					end
				end

				stdnse.print_debug(1, "Found %d links", found)
			end
		end
	end
end

