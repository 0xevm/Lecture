// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title RecordMapping
contract Storage {
    int256 value;
    mapping(address => int256) map;
    mapping(int256 => mapping(int256 => int256)) doubleMap;
    uint256[] public arr;

    function setMap(address addr, int256 val) public {
        map[addr] = val;
    }

    function setDoubleMap(int256 i, int256 j) public {
        doubleMap[i][j] = i * j;
    }

    function pushArray(uint256 i) public {
        arr.push(i);
    }

    function getArrayLength() public view returns (uint256) {
        return arr.length;
    }
}
