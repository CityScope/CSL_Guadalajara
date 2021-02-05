// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
contract Vaccine{
    //Struct vaccine
    struct Envio{
        address address_who_sends;
        address address_to_sends;
        string type_vaccine;
        uint amount_vaccine;
        string processes;
        string no_serie_container;
        uint256 date_of_expiry;
        uint256 shipping_date;
        bool send;
    }

    //Mapping of address to envio struct
    mapping (address => Envio) public mapEnvio;

    //Envio Event
    event EnvioAdded(
        address indexed _address_who_sends,
        address indexed _address_to_send,
        string _type_vaccine, 
        uint256 _amount_vaccine,
        string _processes, 
        string _no_serie_container, 
        uint256 _date_of_expiry, 
        uint256 _shipping_date);

    //function to add envio
    function addEnvio(
        address _address_who_sends, 
        address _address_to_send, 
        string memory _type_vaccine,
        uint256 _amount_vaccine,
        string memory _processes,
        string memory _no_serie_container,
        uint256 _date_of_expiry,
        uint256 _shipping_date) public returns (bool _success){
            
        Envio memory envio = Envio(
            _address_who_sends,
            _address_to_send,
            _type_vaccine,
            _amount_vaccine,
            _processes,
            _no_serie_container,
            _date_of_expiry,
            _shipping_date,
            true
        );

        mapEnvio[_address_who_sends] = envio;
        emit EnvioAdded(
            _address_who_sends,
            _address_to_send,
            _type_vaccine,
            _amount_vaccine,
            _processes,
            _no_serie_container,
            _date_of_expiry,
            _shipping_date
        );
        _success = true;
    }


    function viewEnvio(address _account) public view returns(address _address_to_send, string memory _type_vaccine, uint256 _amount_vaccine, string memory _processes, string memory _no_serie_container, uint256 _date_of_expiry, uint256 _shipping_date){
        Envio memory envio = mapEnvio[_account];
        _address_to_send = envio.address_to_sends;
        _type_vaccine = envio.type_vaccine;
        _amount_vaccine = envio.amount_vaccine;
        _processes = envio.processes;
        _no_serie_container = envio.no_serie_container;
        _date_of_expiry = envio.date_of_expiry;
        _shipping_date = envio.shipping_date;
    }

}
