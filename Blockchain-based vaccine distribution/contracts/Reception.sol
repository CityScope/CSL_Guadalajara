// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
contract Reception{

    //Struct of received vaccines
    struct Received{
        address address_who_sent;
        address address_who_received;
        string No_serie_container;
        uint256 amount_vaccine;
        string type_vaccine;
        string state;
        uint256 date_reception;
        bool rec;
    }

    //mapping of addres to Received struct
    mapping (address => Received) public mapReceived;

    //Received Event
    event VaccineReceived(
        address indexed _address_who_sent,
        address indexed _address_who_received,
        string No_serie_container,
        uint256 _amount_vaccine,
        string _type_vaccine,
        string _state,
        uint256 _date_reception
    );

    //function to add reception data
    function addReceived(
        address _address_who_sent,
        address _address_who_received,
        string memory _No_serie_container,
        uint256 _amount_vaccine,
        string memory _type_vaccine,
        string memory _state,
        uint256 _date_reception
    ) public returns (bool _success){
        
        Received memory received = Received(
            _address_who_sent,
            _address_who_received,
            _No_serie_container,
            _amount_vaccine,
            _type_vaccine,
            _state,
            _date_reception,
            true
        );

        mapReceived[_address_who_received] = received;

        emit VaccineReceived(
            _address_who_sent,
            _address_who_received,
            _No_serie_container,
            _amount_vaccine,
            _type_vaccine,
            _state,
            _date_reception
        );
        _success = true;
    }


    function viewReceived(address _account) public view returns(address _address_who_sent, string memory _No_serie_container, uint256 _amount_vaccine, string memory _type_vaccine, string memory _state, uint256 _date_reception){
        Received memory received = mapReceived[_account];
        _address_who_sent = received.address_who_sent;
        _No_serie_container = received.No_serie_container;
        _amount_vaccine = received.amount_vaccine;
        _type_vaccine = received.type_vaccine;
        _state = received.state;
        _date_reception = received.date_reception;
    }

}
