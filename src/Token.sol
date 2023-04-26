// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GLDToken is ERC20 {
    struct Struct {
        address addr;
        uint256 val;
    }

    Struct[] public arr;

    constructor(uint256 initialSupply) ERC20("Gold", "GLD") {
        _mint(msg.sender, initialSupply);
    }

    function pushArr(address _addr, uint256 _val) public {
        arr.push(Struct(_addr, _val));
    }
}
