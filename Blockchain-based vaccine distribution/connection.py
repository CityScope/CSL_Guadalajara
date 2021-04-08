import socket
import os

from _thread import * 
from html.entities import name2codepoint 

import re 
import xml.etree.ElementTree as ET
import prueba

import time

my_data = []
tam = 0

activate = False
count = 0
sa = 0


ServerSocket = socket.socket()
host = '127.0.0.1'
port = 9999
ThreadCount = 0
try:
    ServerSocket.bind((host, port))
except socket.error as e:
    print(str(e))

print('Waitiing for a Connection..')
ServerSocket.listen(1)

def decode_xml_replacer(match):
  name=match.group(1)
  if(name.startswith("#")):
    return chr(int(name[1:],16))
  return chr(name2codepoint.get(name,'?'))

def decode_xml_string(s):
    st=re.sub("&(.*?);",decode_xml_replacer,s)
    return st

def clean_xml(message):
    msg = decode_xml_string(message)
    char_to_remove = 0
    for elem in msg:
        if elem == '<':
            break
        char_to_remove += 1

    msg_g = msg[char_to_remove:]
    tree = ET.ElementTree(ET.fromstring(msg_g))
    return tree


def send_udp_message(msgFromClient):
    # msgFromClient = "Hello UDP Server"

    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9877)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)


def get_contents(xml_msg,xml_path):
    root = xml_msg.getroot()
    result=""
    for form in root.findall(xml_path):
        result+=form.text
    return result

def save_blockchain():
    
  
    for j in my_data:
        new_message = j.split()
        print(new_message)
        if new_message[0] == "Enviar":
            account_who_send = int(new_message[1])
            account_to_send = int(new_message[2])
            amount = int(new_message[4])
            date_expiry = int(new_message[7])
            date_shipping = int(new_message[8])
            prueba.shipping_contracts(account_who_send, account_to_send, new_message[3], amount, new_message[5], new_message[6], date_expiry, date_shipping)
        if new_message[0] == "Recibir":
            account_who_sent = int(new_message[1])
            account_who_received = int(new_message[2])
            amount_vaccine = int(new_message[4])
            date_reception = int(new_message[7])
            prueba.reception_contract(account_who_sent, account_who_received,new_message[3], amount_vaccine, new_message[5], new_message[6], date_reception)
        if new_message[0] == "Aplicar":
            date_application = int(new_message[1])
            age_people = int(new_message[2])
            prueba.application_contract(date_application, age_people, new_message[3])
   

def assign_zise_list(con):
    ele = con.split()
    d = int(ele[1])
    tam = d
    print(tam)
    print(len(my_data))
    print(sa)
    #send data of vaccine application to another account
    #Aquí se aplican las vacunas
    prueba.send_token(3, 4, tam)

    r = tam + 1
    if tam == sa:
        print("Ande k")       
        save_blockchain()
        #Aqui mandar mensaje a gama con el numero de tokens virtuales
    
def send_tokens_gama(num):
    prueba.view_Tokens(num)
    

def threaded_client(connection,):
    global count
    global cant
    global sa
    connection.send(str.encode('Welcome to the Server\n'))
    while True:
        data = connection.recv(2048)
        msg = data.decode('utf-8')
        try:
            if "ummisco.gama.network.common.CompositeGamaMessage" in msg:
                xml_msg = clean_xml(msg)
                content = get_contents(xml_msg, "./contents/string")
                
                my_data.append(content)
                #print(content)

                spli = content.split()
                print(spli)

            
                if spli[0] == "Recibir":
                    activate = True
                    if activate == True:
                       
                        prueba.send_token(count, count + 1, int(spli[4]))
                        print(count)
                        print(count + 1)
                        count += 1
                        #send_udp_message(content)
                        activate = False
                
                #To send the received transactions
                #if spli[0] == "Enviar" or spli[0] == "Aplicar":
                    #send_udp_message(content)
                if spli[0] == "Aplicar":
                    sa+= 1
                    send_udp_message(content)

                if spli[0] == "request":
                    send_tokens_gama(0)

                #Asignar el tamaño de la lista
                #To stores in Blockchain and send ethereum transactions
                if spli[0] == "Size":
                    assign_zise_list(content)
                
                    
                
            else:
                print(msg)

        except:
            print("----------------------------------------------")
            
        if not data:
            break


    connection.close()


while True:
    Client, address = ServerSocket.accept()
    print('Connected to: ' + address[0] + ':' + str(address[1]))
    start_new_thread(threaded_client, (Client, ))
    ThreadCount += 1
    print('Thread Number: ' + str(ThreadCount))
ServerSocket.close()

