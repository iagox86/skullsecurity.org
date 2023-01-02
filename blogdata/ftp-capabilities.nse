description = [[
Checks the capabilities of the given FTP user (anonymous by default). This currently
Attempts:
* RSTATUS
* MKDIR
* RMDIR

These were chosen because they're required for the following exploit:
http://seclists.org/fulldisclosure/2009/Aug/0443.html

]]
--
-- @output
-- Interesting ports on 208.81.2.52:
-- PORT   STATE SERVICE
-- 21/tcp open  ftp
-- |  ftp-capabilities: Using user: 'ron'
-- |  |_ Not a Windows server
-- |  |_ MKDIR: Allowed
-- |_ |_ RMDIR: Allowed
-- 
-- @args ftpuser Alternate user to initiate the FTP session (defaults to 'anonymous')
-- @args ftppass Alternate password to initiate the FTP session (defaults to 'IEUser@')

description="Checks to see if a Microsoft ISS FTP server allows anonymous logins and MKDIR (based on anonftp.nse by Eddie Bell <ejlbell@gmail.com>)"
author = "Xavier Mertens <xavier@rootshell.be>, Ron Bowes <ron@skullsecurity.net>"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"default", "auth", "intrusive"}

require "shortport"
require "stdnse"

portrule = shortport.port_or_service(21, "ftp")

---Connects to the ftp server and checks if the server allows
-- anonymous logins or any credentials passed as arguments
local function go(host, port)
	local status, result
	local message = "Exited in unknown state; please report"
	local isWindows = false
	local allowMkdir = false
	local allowRmdir = false

	local err_catch = function()
		socket:close()
	end

	stdnse.print_debug(1, "ftp-capabilities: Connecting to FTP server")

	local socket = nmap.new_socket()
	socket:set_timeout(5000)
	status, result = socket:connect(host.ip, port.number, port.protocol)
	if(not(status)) then
		socket:close()
		return false, "Failed to connect: " .. result
	end

	local user = "anonymous"
	local pass = "IEUser@"

	if(type(nmap.registry.args.ftpuser) == "string") then
		user = nmap.registry.args.ftpuser
	end

	if(type(nmap.registry.args.ftppass) == "string") then
		pass = nmap.registry.args.ftppass
	end

	local struser = string.format("USER %s\r\n", user)
	local strpass = string.format("PASS %s\r\n", pass)

	stdnse.print_debug(1, "ftp-capabilities: Sending username and password")
	status, result = socket:send(struser)
	if(status == false) then
		socket:close()
		return false, "Couldn't send: " .. result
	end
	status, result = socket:send(strpass)
	if(status == false) then
		socket:close()
		return false, "Couldn't send: " .. result
	end

	local buffer = stdnse.make_buffer(socket, "\r?\n")
	-- Receive the first line
	local line = buffer()

	-- Loop over the lines
	while line do
		stdnse.print_debug(1, "ftp-capabilities: Received: %s", line)

		-- 230 Login successful.
		if(string.match(line, "^230")) then
			stdnse.print_debug(1, "ftp-capabilities: Successfully authenticated as '%s'!", user)
			stdnse.print_debug(1, "ftp-capabilities: Sending RSTATUS")
			status, result = socket:send("RSTATUS\r\n")
			status, result = socket:send("MKD NMAPTEST\r\n")
			if(status == false) then
				socket:close()
				return false, result
			end
		end

		-- 500 Unknown command.
		if(string.match(line, "^500")) then
			stdnse.print_debug(1, "ftp-capabilities: Received an error: %s", line)
		end

		-- 211-Microsoft FTP Service
		if(string.match(line, "^211-Microsoft FTP Service")) then
			isWindows = true
			stdnse.print_debug(1, "ftp-capabilities: Server is Microsoft FTP", user)
		end

		-- 257 "/home/ron/NMAPTEST" created
		if(string.match(line, "^257")) then
			allowMkdir = true

			stdnse.print_debug(1, "ftp-capabilities: Server allows '%s' to create directories", user)
			stdnse.print_debug(1, "ftp-capabilities: Removing directory")
			status, result = socket:send("RMD NMAPTEST\r\n")

			if(status == false) then
				socket:close()
				return false, result
			end
		end

		-- 250 Remove directory operation successful.
		if(string.match(line, "^250")) then
			allowRmdir = true

			stdnse.print_debug(1, "ftp-capabilities: Directory successfully removed", user)

			break; -- Leave early
		end

		-- 550 Create directory operation failed.
		if(string.match(line, "^550")) then
			stdnse.print_debug(1, "ftp-capabilities: Server doesn't all '%s' to create directories", user)

			message = string.format("Server doesn't allow '%s' to create directories.", user)

			break; -- Kill the loop
		end

		-- Receive the next line
		line = buffer()
	end

	socket:close()

	local response = string.format("Using user: '%s'\n", user)

	if(isWindows) then
		response = response .. "|_ Windows server\n"
	else
		response = response .. "|_ Not a Windows server\n"
	end

	if(allowMkdir) then
		response = response .. "|_ MKDIR: Allowed\n"
	else
		response = response .. "|_ MKDIR: Denied\n"
	end

	if(allowRmdir) then
		response = response .. "|_ RMDIR: Allowed\n"
	else
		response = response .. "|_ RMDIR: Denied\n"
	end

	return true, response
end

action = function(host, port)
	local status, result = go(host, port)

	if(status == false) then
		if(nmap.debugging() > 0) then
			return "ERROR: " .. result
		else
			return nil
		end
	end

	return result
end

