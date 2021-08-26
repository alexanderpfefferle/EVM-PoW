// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract SymmetricMatrix {

    address owner;
    // makes sure that no one can claim a bounty twice
    mapping (bytes32 => bool) already_submitted;
    // these are public so that anyone can easily check whether
    // there is still a bounty and how hard the PoW will be
    bytes32 public target;
    bool public active;
    // the problem parameters
    uint[][] matrix;

    constructor(uint[][] memory _matrix, bytes32 _target) payable {
        require (msg.value >= 0.1 ether, "insufficient rewards");
        require(_matrix.length == _matrix[0].length, "matrix doesn't have equal dimensions");
        owner = msg.sender;
        matrix = _matrix;
        target = _target;
        active = true;
    }
    
    function mcg(uint seed) private pure returns (uint next_seed) {
        return ((seed % type(uint128).max) * 0xca9634b976f622d450b386f6ec5fa0a5 + 0xdeadf00ddeadf00d) % type(uint128).max;
    }
    
    function offChain(uint rand) public view returns (bool isCounterexample, bytes32 _hashValue) {
        // compute the initial hash, which consists of the sender and given input,
        // this makes sure the hash is different if either of these changes
        bytes32 hashValue = keccak256(abi.encodePacked(msg.sender, rand));
        // we use the hash as a random number and not the original input,
        // to make sure that the submission of a counterexample can't be frontrun
        rand = uint(hashValue);
        // makes sure the initial hash is in memory at 0x80
        assembly{
            mstore(0x80,hashValue)
        }
        
        // the computation we want to incentivize
        // (the corresponding bytecode will be modified to update the hash)
        uint rand1 = mcg(rand);
        uint rand2 = mcg(rand1);
        uint index1 = rand1 % (matrix.length);
        uint index2 = rand2 % (matrix[0].length); // needs to be symmetric anyway
        isCounterexample = matrix[index1][index2] != matrix[index2][index1];
        
        // takes the final hash out of memory at 0x80
        assembly{
            _hashValue:=mload(0x80)
        }
    }

    function onChain(uint rand) public {
        bool isCounterexample;
        bytes32 hashValue;
        (isCounterexample, hashValue) = offChain(rand);
        require(!already_submitted[hashValue], "hash already submitted");
        already_submitted[hashValue] = true;
        
        // (vandal doesn't support new london opcodes yet, so basefee can't be used)
        // use the new basefee opcode to get current gasPrice
        // and an overestimation of the required gas to
        // pay more than the TX-fee for rewards
        // uint txFeeRefund = (block.basefee + 1 gwei) * 100000;
        
        // ~25 gwei gasPrice on mainnet at 21.8.2021, <= 100000 gas required
        uint txFeeRefund = (25 gwei) * 100000;
        if (active && isCounterexample) {
            // 0.004 ether bounty for counterexample
            payable(msg.sender).transfer(txFeeRefund + 0.004 ether);
            payable(owner).transfer(address(this).balance);
            active = false;
        }
        if (active && hashValue < target) {
            // 0.001 reward for the PoW
            payable(msg.sender).transfer(txFeeRefund + 0.001 ether);
        }
    }
}

