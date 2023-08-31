// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NumberStorage {

    /// @custom:storage-location erc7201:number.storage
    bytes32 public constant NUMBER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("number.storage")) - 1));

    struct Data {
        uint256 number;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = NUMBER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract IncrementDecrement {

    function incrementNumber() public {
        NumberStorage.data().number += 1;
    }

    function decrementNumber() public {
        NumberStorage.data().number -= 1;
    }    
}

contract IncrementDecrementGetBug {

    function incrementNumber() public {
        NumberStorage.data().number += 1;
    }

    function decrementNumber() public {
        // Bug: += instead of -=
        NumberStorage.data().number += 1;
    }

    function getNumber() public view returns (uint256) {
        return NumberStorage.data().number;
    }
}

contract DecrementFixed {
    function decrementNumber() public {
        // Bug: -= instead of +=
        NumberStorage.data().number -= 1;
    }
}

contract IncrementDecrementGet {

    function incrementNumber() public {
        NumberStorage.data().number += 1;
    }

    function decrementNumber() public {
        NumberStorage.data().number -= 1;
    }

    function getNumber() public view returns (uint256) {
        return NumberStorage.data().number;
    }
}

contract Receive {
    receive() external payable {}
}

contract IncrementDecrementReceive is Receive {

    function incrementNumber() public {
        NumberStorage.data().number += 1;
    }

    function decrementNumber() public {
        NumberStorage.data().number -= 1;
    }

    function getNumber() public view returns (uint256) {
        return NumberStorage.data().number;
    }
}

contract MultiplyDivide {

    function multiplyNumber(uint256 _multiplier) public {
        NumberStorage.data().number *= _multiplier;
    }

    function divideNumber(uint256 _divisor) public {
        NumberStorage.data().number /= _divisor;
    }
}

contract IncrementDecrementMultiply is IncrementDecrementGet, MultiplyDivide {}

contract MultiplyDivideGet {

    function multiplyNumber(uint256 _multiplier) public {
        NumberStorage.data().number *= _multiplier;
    }

    function divideNumber(uint256 _divisor) public {
        NumberStorage.data().number /= _divisor;
    }

    function getNumber() public view returns (uint256) {
        return NumberStorage.data().number;
    }
}

contract AddSubstract {

    function addNumber(uint256 _addend) public {
        NumberStorage.data().number += _addend;
    }

    function subtractNumber(uint256 _subtrahend) public {
        NumberStorage.data().number -= _subtrahend;
    }
}

contract AddSubstractGet {

    function addNumber(uint256 _addend) public {
        NumberStorage.data().number += _addend;
    }

    function subtractNumber(uint256 _subtrahend) public {
        NumberStorage.data().number -= _subtrahend;
    }

    function getNumber() public view returns (uint256) {
        return NumberStorage.data().number;
    }
}