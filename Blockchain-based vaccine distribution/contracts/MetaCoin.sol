// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MetaCoin {
	mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	constructor() public {
		balances[tx.origin] = 5500000;
	}

	function sendCoin(address emis, address receiver, uint amount) public returns(bool sufficient) {
		if (balances[emis] < amount) return false;
		balances[emis] -= amount;
		balances[receiver] += amount;
		emit Transfer(emis, receiver, amount);
		return true;
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}