// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../interface/IFunctionManager.sol";
import "./EnumerableSet.sol";

library FunctionManagerStorage {

    /// @custom:storage-location erc7201:function.manager.storage
    bytes32 public constant FUNCTION_MANAGER_STORAGE = keccak256(abi.encode(uint256(keccak256("function.manager.storage")) - 1));

    struct Data {
        EnumerableSet.Bytes32Set allFunctions;
        mapping(bytes4 => IFunctionManager.FunctionWithMetadata) functionData;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = FUNCTION_MANAGER_STORAGE;
        assembly {
            data_.slot := position
        }
    }
}