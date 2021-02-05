import json
from web3 import Web3, HTTPProvider
import socket

blockchain_address = 'http://127.0.0.1:7545'
web3 = Web3(HTTPProvider(blockchain_address))



def shipping_contracts(account_who_send, account_to_send, vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date):
    web3.eth.defaultAccount = web3.eth.accounts[account_who_send]
    compiled_contract_path = 'build/contracts/Vaccine.json'
    deployed_contract_address = '0x4535a41A57D5c893270a71870FB6a30F41a2B372'
    
    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addEnvio(web3.eth.defaultAccount,web3.eth.accounts[account_to_send],vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date).transact()
    send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))


def reception_contract(address_who_sent, address_who_received, No_serie_container, amount_vaccine, type_vaccine, state, date_reception):
    web3.eth.defaultAccount = web3.eth.accounts[address_who_sent]
    compiled_contract_path = 'build/contracts/Reception.json'
    deployed_contract_address = '0xBdb6729e535366Cc05693Ab0aD4Bab57ae61AE6E'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addReceived(web3.eth.defaultAccount,web3.eth.accounts[address_who_received],No_serie_container, amount_vaccine, type_vaccine, state, date_reception).transact()
    send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))

def application_contract(date_application, age_people, morbidity):
    web3.eth.defaultAccount = web3.eth.accounts[0]
    compiled_contract_path = 'build/contracts/Application.json'
    deployed_contract_address = '0x4b4CAF31ca277E1cc0d8350586CEB28b07547138'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addApplication(date_application, age_people, morbidity).transact()
    send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))


def send_udp_message(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9876)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)


