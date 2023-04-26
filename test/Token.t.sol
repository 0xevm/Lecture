// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std-new/Test.sol";
import "../src/Token.sol";

contract GLDTokenTest is Test {
    GLDToken public token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address eva = makeAddr("eva");
    address ken = makeAddr("ken");

    function setUp() public {
        token = new GLDToken(100000 ether);
        token.pushArr(alice, 42);
        token.pushArr(bob, 24);
    }

    function testStorage() public {
        emit log_string("-----start recording------");
        vm.startMappingRecording();

        emit log_string("-----transfer token to alice, bob, eva, ken------");

        token.transfer(alice, 100 ether);
        token.transfer(bob, 200 ether);
        token.transfer(eva, 300 ether);
        token.transfer(ken, 400 ether);

        emit log_named_address("test contract", address(address(this)));
        emit log_named_uint("test contract balance", token.balanceOf(address(this)));

        emit log_named_address("alice", alice);
        emit log_named_uint("alice balance", token.balanceOf(alice));

        emit log_named_address("bob", bob);
        emit log_named_uint("bob balance", token.balanceOf(bob));

        emit log_named_address("eva", eva);
        emit log_named_uint("eva balance", token.balanceOf(eva));

        emit log_named_address("ken", ken);
        emit log_named_uint("ken balance", token.balanceOf(ken));

        emit log_string("\n");

        emit log_string("-----alice approve bob, eva, ken------");
        vm.startPrank(alice);
        token.approve(bob, 101 ether);
        token.approve(eva, 102 ether);
        token.approve(ken, 103 ether);
        vm.stopPrank();

        emit log_named_uint("allowance[alice][bob]", token.allowance(alice, bob));
        emit log_named_uint("allowance[alice][eva]", token.allowance(alice, eva));
        emit log_named_uint("allowance[alice][ken]", token.allowance(alice, ken));

        emit log_string("-----bob approve alice, eva, ken------");
        vm.startPrank(bob);
        token.approve(alice, 201 ether);
        token.approve(eva, 202 ether);
        token.approve(ken, 203 ether);
        vm.stopPrank();

        emit log_named_uint("allowance[bob][alice]", token.allowance(bob, alice));
        emit log_named_uint("allowance[bob][eva]", token.allowance(bob, eva));
        emit log_named_uint("allowance[bob][ken]", token.allowance(bob, ken));

        emit log_string("-----eva approve alice, bob, ken------");
        vm.startPrank(eva);
        token.approve(alice, 301 ether);
        token.approve(bob, 302 ether);
        token.approve(ken, 303 ether);
        vm.stopPrank();

        emit log_named_uint("allowance[eva][alice]", token.allowance(eva, alice));
        emit log_named_uint("allowance[eva][bob]", token.allowance(eva, bob));
        emit log_named_uint("allowance[eva][ken]", token.allowance(eva, ken));

        emit log_string("-----ken approve alice, bob, eva------");
        vm.startPrank(ken);
        token.approve(alice, 401 ether);
        token.approve(bob, 402 ether);
        token.approve(eva, 403 ether);
        vm.stopPrank();

        emit log_named_uint("allowance[ken][alice]", token.allowance(ken, alice));
        emit log_named_uint("allowance[ken][bob]", token.allowance(ken, bob));
        emit log_named_uint("allowance[ken][eva]", token.allowance(ken, eva));

        emit log_string("\n");
        emit log_string("-----a long time has passed-----");

        bytes32 balanceSlot = bytes32(uint256(0));
        bytes32 allowanceSlot = bytes32(uint256(1));
        bytes32 arrSlot = bytes32(uint256(5));

        emit log_named_uint("total supply", uint(vm.load(address(token), bytes32(uint256(2)))));

        emit log_string("\n");
        emit log_string("\n");
        emit log_string("-----Balance-----");
        emit log_string("-----get all hodler-----");
        uint256 balanceLen = vm.getMappingLength(address(token), balanceSlot);
        emit log_named_uint("hodler amount", balanceLen);
        for (uint256 i; i < balanceLen; i++) {
            bytes32 slot = vm.getMappingSlotAt(address(token), balanceSlot, i);
            emit log_named_bytes32("slot", slot);

            emit log_named_address("user", address(uint160(vm.getMappingKeyOf(address(token), slot))));
            emit log_named_uint("value", uint256(vm.load(address(token), slot)));
        }

        // map slot = keccak(key, map_slot);
        emit log_string("\n");
        emit log_string("-----map slot = keccak(key, map_slot)-----");
        for (uint256 i; i < balanceLen; i++) {
            emit log_named_bytes32("slot1", vm.getMappingSlotAt(address(token), balanceSlot, i));
            emit log_named_bytes32("slot2", keccak256(abi.encode(getUser(i), balanceSlot)));
        }

        // 给定一个 slot，我们知道它属于哪个数据结构
        emit log_string("\n");
        emit log_string("-----test getMappingParentOf-----");
        emit log_named_uint(
            "alice's balance slot",
            uint256(vm.getMappingParentOf(address(token), keccak256(abi.encode(alice, balanceSlot))))
        );
        emit log_named_uint(
            "bob's balance slot",
            uint256(vm.getMappingParentOf(address(token), keccak256(abi.encode(bob, balanceSlot))))
        );
        emit log_string("slot 0 is _balances, so both are one of _balances's item");

        emit log_string("\n");
        emit log_string("\n");

        emit log_string("-----allowance-----");
        // 哪些人的 token 允许哪些人使用了？
        uint256 allowanceLen = vm.getMappingLength(address(token), allowanceSlot);
        emit log_named_uint("allowance amount", allowanceLen);
        for (uint256 i; i < allowanceLen; i++) {
            bytes32 userSlot = vm.getMappingSlotAt(address(token), allowanceSlot, i);
            emit log_named_bytes32("user slot", userSlot);

            address user = address(uint160(vm.getMappingKeyOf(address(token), userSlot)));
            emit log_named_address("user", user);
            uint256 userLen = vm.getMappingLength(address(token), userSlot);
            emit log_named_uint("how many users are allowed by this user", userLen);
            for (uint256 j; j < userLen; j++) {
                bytes32 allowedUserSlot = vm.getMappingSlotAt(address(token), userSlot, j);
                emit log_named_bytes32("allowedUserSlot", allowedUserSlot);
                emit log_named_address(
                    "allowed user", address(uint160(vm.getMappingKeyOf(address(token), allowedUserSlot)))
                );
                emit log_named_uint("allowed value", uint256(vm.load(address(token), allowedUserSlot)));
            }
            emit log_string("\n");
        }

        emit log_string("\n");
        emit log_string("\n");

        emit log_string("-----array-----");
        emit log_named_uint("arr.length", uint256(vm.load(address(token), arrSlot)));
        bytes32 arr0_slot = keccak256(abi.encode(arrSlot));
        emit log_named_bytes32("arr0_slot", arr0_slot);
        emit log_named_address("arr0.addr", address(uint160(uint256(vm.load(address(token), arr0_slot)))));
        emit log_named_uint("arr0.val", uint256(vm.load(address(token), bytes32(uint256(arr0_slot) + 1))));

        emit log_named_address(
            "arr1.addr", address(uint160(uint256(vm.load(address(token), bytes32(uint256(arr0_slot) + 2)))))
        );
        emit log_named_uint("arr1.val", uint256(vm.load(address(token), bytes32(uint256(arr0_slot) + 3))));


        bytes32 slot0 = keccak256(abi.encode(bob, keccak256(abi.encode(ken, 1))));
        emit log_named_bytes32("slot0", slot0);
        emit log_named_uint("402 ether", uint(vm.load(address(token), slot0)));
    }

    function getUser(uint256 i) internal view returns (address) {
        if (i == 0) {
            return address(this);
        } else if (i == 1) {
            return alice;
        } else if (i == 2) {
            return bob;
        } else if (i == 3) {
            return eva;
        } else if (i == 4) {
            return ken;
        } else {
            return address(0xff);
        }
    }
}
