#client side
import serial
import socket
import sys
import os


#sort out serial stuff
ser = serial.Serial('/dev/ttyACM1',9600,timeout = 10)

server_address = './server_socket'

# Create a UDS socket
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# Connect the socket to the port where the server is listening
server_address = './server_socket'
print (sys.stderr, 'connecting to %s' % server_address)
try:
    sock.connect(server_address)
except socket.error, msg:
    print (sys.stderr, msg)
    sys.exit(1)


while True:
	#receive data over COM
	data = ser.readline()
	print(data)
	sock.sendall(data)


