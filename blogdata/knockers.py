# python2 please

import sys
import struct
import hashlib
import os
from binascii import hexlify, unhexlify
import SocketServer
import socket

try:
	from fw import allow
except ImportError:
	def allow(ip,port):
		print 'allowing host ' + ip + ' on port ' + str(port)

PORT = 8008

g_h = hashlib.sha512
g_key = None

def generate_token(h, k, *pl):
	m = struct.pack('!'+'H'*len(pl), *pl)
	mac = h(k+m).digest()
	return mac + m

def parse_and_verify(h, k, m):
	ds = h().digest_size
	if len(m) < ds:
		return None
	mac = m[:ds]
	msg = m[ds:]
	if h(k+msg).digest() != mac:
		return None
	port_list = []
	for i in range(0,len(msg),2):
		if i+1 >= len(msg):
			break
		port_list.append(struct.unpack_from('!H', msg, i)[0])
	return port_list

class KnockersRequestHandler(SocketServer.BaseRequestHandler):
	def handle(self):
		global g_key
		data, s = self.request
		print 'Client: {} len {}'.format(self.client_address[0],len(data))
		l = parse_and_verify(g_h, g_key, data)
		if l is None:
			print 'bad message'
		else:
			for p in l:
				allow(self.client_address[0], p)

class KnockersServer(SocketServer.UDPServer):
	address_family = socket.AF_INET6

def load_key():
	global g_key
	f=open('secret.txt','rb')
	g_key = unhexlify(f.read())
	f.close()

def main():
	global g_h
	global g_key
	g_h = hashlib.sha512
	if len(sys.argv) < 2:
		print '''Usage:
--- Server ---
knockers.py setup
    Generates a new secret.txt
knockers.py newtoken port [port [port ...]]
    Generates a client token for the given ports
knockers.py serve
    Runs the service
--- Client ---
knockers.py knock <host> <token>
    Tells the server to unlock ports allowed by the given token
'''
	elif sys.argv[1]=='serve':
		load_key()
		server = KnockersServer(('', PORT), KnockersRequestHandler)
		server.serve_forever();
	elif sys.argv[1]=='setup':
		f = open('secret.txt','wb')
		f.write(hexlify(os.urandom(16)))
		f.close()
		print 'wrote new secret.txt'
	elif sys.argv[1]=='newtoken':
		load_key()
		ports = map(int,sys.argv[2:])
		print hexlify(generate_token(g_h, g_key, *ports))
	elif sys.argv[1]=='knock':
		ai = socket.getaddrinfo(sys.argv[2],PORT,socket.AF_INET6,socket.SOCK_DGRAM)
		if len(ai) < 1:
			print 'could not find address: ' + sys.argv[2]
			return
		family, socktype, proto, canonname, sockaddr = ai[0]
		s = socket.socket(family, socktype, proto)
		s.sendto(unhexlify(sys.argv[3]), sockaddr)
	else:
		print 'unrecognized command'

if __name__ == '__main__':
	main()
