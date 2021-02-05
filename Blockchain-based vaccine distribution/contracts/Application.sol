// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;
//Contract to vaccine aplication
contract Application{

    //struct of aplication
    struct Application_Vaccine{
        uint256 date_application;
        uint256 age_people;
        string morbidity;
        bool app;
    }

    //Number of applications
    uint public Number;

    //Mapping of account to application structure
    mapping(uint => Application_Vaccine) public appVaccine;

    //Vaccine application event
    event ApplicationAdded(uint256 _date_application, uint256 _age_people, string _morbidity);

    //Function to vaccine apply
    function addApplication(
        uint256 _date_application,
        uint256 _age_people,
        string memory _morbidity
    ) public returns (bool _success){
        Application_Vaccine memory application_vaccine = Application_Vaccine(
            _date_application,
            _age_people,
            _morbidity,
            true
        );

        appVaccine[Number] = application_vaccine;
        Number++;

        emit ApplicationAdded(_date_application, _age_people, _morbidity);
        _success = true;
    }

    //function to view all the applications
    function getApplications() external view returns(uint256[] memory, uint256[] memory, string[] memory){
        uint256[] memory _date_application = new uint256[] (Number);
        uint256[] memory _age_people = new uint256[] (Number);
        string[] memory _morbidity = new string[] (Number);
        for(uint256 i = 0; i < Number; i++){
            _date_application[i] = appVaccine[i].date_application;
            _age_people[i] = appVaccine[i].age_people;
            _morbidity[i] = appVaccine[i].morbidity;
        }
        return (_date_application, _age_people, _morbidity);
    }
}