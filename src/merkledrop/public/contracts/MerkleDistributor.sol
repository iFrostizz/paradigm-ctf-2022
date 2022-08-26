// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./MerkleProof.sol";

interface ERC20Like {
    function transfer(address dst, uint qty) external returns (bool);
}

contract MerkleDistributor {

    event Claimed(uint256 index, address account, uint256 amount);

    address public immutable token;
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // @ctf index + account + amount = 32 + 20 + 12 = 64 bytes
    // @ctf merkleProof = 32 bytes array. 2 proofs = 64 bytes
    // @ctf so we can skip the first leaf
    // @ctf pass index, account, amount as first leaf
    // @ctf we need to find an amount that is < 75.000 * 1e18 in the proof
    function claim(uint256 index, address account, uint96 amount, bytes32[] memory merkleProof) external {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(ERC20Like(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
}