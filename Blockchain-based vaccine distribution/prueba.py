import json
from web3 import Web3, HTTPProvider
import socket

blockchain_address = 'http://127.0.0.1:7545'
web3 = Web3(HTTPProvider(blockchain_address))


def shipping_contracts(account_who_send, account_to_send, vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date):
    web3.eth.defaultAccount = web3.eth.accounts[account_who_send]
    compiled_contract_path = 'build/contracts/Vaccine.json'
    deployed_contract_address = '0x4d3EcD79769DDa3E35D6131C68236eB910d4e760'
    
    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addEnvio(web3.eth.defaultAccount,web3.eth.accounts[account_to_send],vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date).transact()
    #send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))


def reception_contract(address_who_sent, address_who_received, No_serie_container, amount_vaccine, type_vaccine, state, date_reception):
    web3.eth.defaultAccount = web3.eth.accounts[address_who_sent]
    compiled_contract_path = 'build/contracts/Reception.json'
    deployed_contract_address = '0xb814650CBEbBe95EaD9b73255EEdAC9d17357ac5'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addReceived(web3.eth.defaultAccount,web3.eth.accounts[address_who_received],No_serie_container, amount_vaccine, type_vaccine, state, date_reception).transact()
    #send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))

def application_contract(date_application, age_people, morbidity):
    web3.eth.defaultAccount = web3.eth.accounts[0]
    compiled_contract_path = 'build/contracts/Application.json'
    deployed_contract_address = '0x355890dA06199eb6f8941B301d97AFbB1c7F550D'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addApplication(date_application, age_people, morbidity).transact()
    send_udp_message2("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))
    

def send_token(emis, recep, amount):
    web3.eth.defaultAccount = web3.eth.accounts[emis]
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0xf8a3F6a93EaCB8c8847EAef456e61bE134B68368'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.sendCoin(web3.eth.defaultAccount, web3.eth.accounts[recep], amount).transact()
    print(tx_hash)
    
def view_Tokens(account):
    
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0xf8a3F6a93EaCB8c8847EAef456e61bE134B68368'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    
    for i in range(2):
        res = contract.functions.getBalance(web3.eth.accounts[account]).call()
        print(res)
        account += 1
        if res != 0:
            send_udp_message(str(res))
        

def view_Tokens_send(account):
   
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0xf8a3F6a93EaCB8c8847EAef456e61bE134B68368'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    #solo 2 porque solo necesitaremos el número de cuentas disponibles
    for i in range(4):
        res = contract.functions.getBalance(web3.eth.accounts[account]).call()
        print(res)
        sa = res
        account += 1
      
        if res != 0:
            send_token(account,0,sa)
            



def send_udp_message(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9876)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)

def send_udp_message2(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9875)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)




#view_Tokens_send(0)
