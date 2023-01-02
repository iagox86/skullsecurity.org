description = [[
Queries the California Department of Motor Vehicles to check the availability of a requested vanity plate. 
The request looks something like this:
https://xml.dmv.ca.gov/IppWebV3/processConfigPlate.do?kidsPlate=&plateType=R&plateLength=7&plateChar0=N&plateChar1=M&plateChar2=A&plateChar3=P&plateChar4=*&plateChar5=*&plateChar6=*

Note that the session has to be established properly before this request is sent. This script looks after 
the initialization, so it's only required if you're sending the request manually. 
]]

---
-- @usage
-- nmap --script=http-california-plates --script-args='plate=NMAP' <host>
--
-- @output
-- 
-- nmap --script=http-california-plates --script-args='plate=ABCDEF' localhost
-- Host script results:
-- |_ http-california-plates: Plate is not available!
-- 
-- nmap --script=http-california-plates --script-args='plate=NMAP' localhost
-- Host script results:
-- |_ http-california-plates: Plate is available!
-- 
-- nmap --script=http-california-plates --script-args='plate=ABC`EF' localhost
-- Host script results:
-- |_ http-california-plates: Plate contains invalid characters!
--
-- @args plate The plate to look up. Has to be between 2 and 7 characters, inclusive. 
-----------------------------------------------------------------------

author = "Ron Bowes"
copyright = "Ron Bowes"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"discovery"}

require 'http'
require 'stdnse'
require 'nsedebug'


hostrule = function(host)
	return true
end

action = function(host)
	local response
	local header = {}

	-- Get the plate and verify it's a valid format
	local plate = nmap.registry.args.plate
	if(plate == nil) then
		return "ERROR: Please pass the script argument 'plate', with the value of the requested plate"
	end

	if(string.len(plate) < 2 or string.len(plate) > 7) then
		return "ERROR: Plate has to be between 2 and 7 characters (inclusive)"
	end

	-- Convert the plate to uppercase and pad with astrisks (that's the format the form expects)
	plate = string.upper(plate)
	while(string.len(plate) < 7) do
		plate = plate .. "*"
	end
	stdnse.print_debug(1, "Checking for plate '" .. plate .. "'...")

	-- Build the request we're going to use
	local request = "kidsPlate=&plateType=R&plateLength=7"
	for i = 1, string.len(plate), 1 do
		local char = string.sub(plate, i, i)
		if(char == ' ') then
			char = '*'
		end

		request = request .. string.format("&plateChar%d=%s", i-1, char)
	end
			
	-- Initialize the personalized plate
	response = http.get( "xml.dmv.ca.gov", {number=443, service="https"}, "/IppWebV3/initPers.do")
	header['Cookie'] = string.sub(response.header['set-cookie'], 1, string.find(response.header['set-cookie'], ";") - 1)

	-- Do the first request (this is required -- an error occurs if we skip it)
	 response = http.post( "xml.dmv.ca.gov", 443, "/IppWebV3/processPers.do", {header=header}, nil, "imageSelected=plateMemorial.jpg&vehicleType=AUTO&isVehLeased=no&plateType=R")

	-- Do the actual request
	response = http.post( "xml.dmv.ca.gov", 443, "/IppWebV3/processConfigPlate.do", {header=header}, nil, request, {header=header})
--io.write(nsedebug.tostr(response))
	-- Check if an invalid string was returned
	local is_invalid = (string.find(response.body, "Your license plate request contains invalid characters") ~= nil)

	-- Check if it was available
	local is_available = (string.find(response.body, "Sorry, The plate you have requested is not available") == nil)

	if(is_invalid) then
		return "Plate contains invalid characters!"
	elseif(is_available) then
		return "Plate is available!"
	else
		return "Plate is not available!"
	end
end


