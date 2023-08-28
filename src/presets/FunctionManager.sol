// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../interface/IFunctionManager.sol";
import "../lib/FunctionManagerStorage.sol";
import "../lib/EnumerableSet.sol";

abstract contract FunctionManager is IFunctionManager {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    function addFunction(FunctionWithMetadata memory _data) external virtual {
        _addFunction(_data);
    }

    function addFunctionBatch(FunctionWithMetadata[] memory functions) external virtual {
        for(uint256 i = 0; i < functions.length; i++) {
            _addFunction(functions[i]);
        }
    }

    function updateFunction(FunctionWithMetadata memory _data) external virtual {
        _updateFunction(_data);
    }

    function updateFunctionBatch(FunctionWithMetadata[] memory functions) external {
        for(uint256 i = 0; i < functions.length; i++) {
            _updateFunction(functions[i]);
        }
    }

    function deleteFunction(bytes4 _functionSelector) external virtual {
        _deleteFunction(_functionSelector);
    }

    function deleteFunctionBatch(bytes4[] memory functionSelector) external {
        for(uint256 i = 0; i < functionSelector.length; i++) {
            _deleteFunction(functionSelector[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _getAllFunctionsWithMetadata() internal view virtual returns (FunctionWithMetadata[] memory functions) {
        bytes32[] memory allFunctions = FunctionManagerStorage.data().allFunctions.values();
        functions = new FunctionWithMetadata[](allFunctions.length);

        for(uint256 i = 0; i < allFunctions.length; i++) {
            bytes4 functionSelector = bytes4(allFunctions[i]);
            functions[i] = FunctionManagerStorage.data().functionData[functionSelector];
        }
    }

    function _addFunction(FunctionWithMetadata memory _data) internal virtual {
        require(_canAddFunction(_data), "FunctionManager: cannot add function");

        bytes4 functionSelector = _data.functionSelector;

        // Check: must not re-add existing function selector.
        require(!FunctionManagerStorage.data().allFunctions.add(functionSelector), "FunctionManager: function already exists");
        require(
                _selectorSignatureMatch(functionSelector, _data.functionSignature),
                "ExtensionState: fn selector and signature mismatch."
            );

        FunctionManagerStorage.data().allFunctions.add(functionSelector);
        FunctionManagerStorage.data().functionData[functionSelector] = _data;

        emit FunctionAdded(functionSelector, _data.implementation, _data);
    }

    function _updateFunction(FunctionWithMetadata memory _data) internal virtual {
        require(_canUpdateFunction(_data), "FunctionManager: cannot update function");

        bytes4 functionSelector = _data.functionSelector;

        // Check: must not update non-existing function selector.
        require(FunctionManagerStorage.data().allFunctions.contains(functionSelector), "FunctionManager: function does not exist");
        require(
                _selectorSignatureMatch(functionSelector, _data.functionSignature),
                "ExtensionState: fn selector and signature mismatch."
            );

        FunctionManagerStorage.data().functionData[functionSelector] = _data;

        emit FunctionUpdated(functionSelector, _data.implementation, _data);
    }

    function _deleteFunction(bytes4 _functionSelector) internal virtual {
        require(_canDeleteFunction(_functionSelector), "FunctionManager: cannot delete function");

        // Check: must not delete non-existing function selector.
        require(FunctionManagerStorage.data().allFunctions.remove(_functionSelector), "FunctionManager: function does not exist");

        FunctionWithMetadata memory functionWithMetadata = FunctionManagerStorage.data().functionData[_functionSelector];
        delete FunctionManagerStorage.data().functionData[_functionSelector];

        emit FunctionDeleted(_functionSelector, functionWithMetadata);
    }

    /// @dev Checks function selector and signature mismatch
    function _selectorSignatureMatch(bytes4 _selector, string memory _signature) internal pure virtual returns (bool fnMatch) {
        /**
         *  Note: `bytes4(0)` is the function selector for the `receive` function.
         *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
        **/
        
        if(_selector == bytes4(0)) {
            fnMatch = keccak256(abi.encode(_signature)) == keccak256(abi.encode("receive()"));
        } else {
            fnMatch = _selector ==
                bytes4(keccak256(abi.encodePacked(_signature)));
        }
    }

    /// @dev Returns whether a new function can be added in the given execution context.
    function _canAddFunction(FunctionWithMetadata memory) internal view virtual returns (bool);
    
    /// @dev Returns whether a function can be updated in the given execution context.
    function _canUpdateFunction(FunctionWithMetadata memory) internal view virtual returns (bool);
    
    /// @dev Returns whether a function can be deleted in the given execution context.
    function _canDeleteFunction(bytes4 functionSelector) internal view virtual returns (bool);
}