//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LW3NFT.sol";

contract LW3NFT2 is LW3NFT {
    
    function test() pure public returns(string memory) {
        return "upgraded";
    }
}