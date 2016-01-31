#server side
import serial
import socket
import sys
import os

ser = serial.Serial('/dev/ttyACM0',9600,timeout = 10)

server_address = './server_socket'

try:
    os.unlink(server_address)
except OSError:
    if os.path.exists(server_address):
        raise

 # Create a UDS socket
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# Bind the socket to the port
print (sys.stderr, 'starting up on %s' % server_address)
sock.bind(server_address)

# Listen for incoming connections
sock.listen(1)

while True:
    connection, client_address = sock.accept()
       # Receive the data in small chunks and retransmit it
    while True:
        data = connection.recv(100)
        print (sys.stderr, 'received "%s"' % data)
        if data:
            print (sys.stderr, 'forwarding data over COM')
            ser.write(data)