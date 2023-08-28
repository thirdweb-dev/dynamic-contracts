// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../core/Router.sol";
import "./FunctionManager.sol";
import "./DefaultFunctions.sol";

abstract contract BaseRouterWithDefaults is Router, FunctionManager {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    address public immutable defaultFunctions;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(FunctionWithMetadata[] memory _functions) {
        defaultFunctions = address(new DefaultFunctions(_functions));
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getAllFunctions() public view virtual override returns (FunctionWithMetadata[] memory functions) {
        
        FunctionWithMetadata[] memory allDefaultFunctions = IRouterState(defaultFunctions).getAllFunctions();
        uint256 allDefaultFunctionsLen = allDefaultFunctions.length;
        
        bytes32[] memory allFunctions = FunctionManagerStorage.data().allFunctions.values();
        uint256 allFunctionsLen = allFunctions.length;

        // Count the number of overrides.
        uint256 overrides = 0;
        for (uint256 i = 0; i < allDefaultFunctions.length; i += 1) {
            if (FunctionManagerStorage.data().allFunctions.contains(allDefaultFunctions[i].functionSelector)) {
                overrides += 1;
            }
        }

        // Create result array, accounting for number of overrides.
        functions = new FunctionWithMetadata[](
            (allDefaultFunctionsLen + allFunctionsLen) - overrides
        );

        uint256 idx = 0;

        // Traverse both arrays in the same loop.
        for(uint256 i = 0; i < (allDefaultFunctionsLen + allFunctionsLen); i += 1) {
            
            if(i < allDefaultFunctionsLen) {
                if (!FunctionManagerStorage.data().allFunctions.contains(allDefaultFunctions[i].functionSelector)) {
                    functions[idx] = allDefaultFunctions[i];   
                    idx += 1;
                }
            } else {
                bytes4 functionSelector = bytes4(allFunctions[i - allDefaultFunctionsLen]);
                functions[idx] = FunctionManagerStorage.data().functionData[functionSelector];
                idx += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _addFunction(FunctionWithMetadata memory _data) internal virtual override {
        require(_canAddFunction(_data), "FunctionManager: cannot add function");

        bytes4 functionSelector = _data.functionSelector;

        require(
            IRouterState(defaultFunctions).getFunction(functionSelector).implementation == address(0),
            "FunctionManager: re-adding default function"
        );

        // Check: must not re-add existing function selector.
        require(!FunctionManagerStorage.data().allFunctions.add(functionSelector), "FunctionManager: function already exists");
        require(
                _selectorSignatureMatch(functionSelector, _data.functionSignature),
                "ExtensionState: fn selector and signature mismatch."
            );
        require(_data.implementation != address(0), "FunctionManager: implementation cannot be zero address");

        FunctionManagerStorage.data().allFunctions.add(functionSelector);
        FunctionManagerStorage.data().functionData[functionSelector] = _data;

        emit FunctionAdded(functionSelector, _data.implementation, _data);
    }

    function _updateFunction(FunctionWithMetadata memory _data) internal virtual override {
        require(_canUpdateFunction(_data), "FunctionManager: cannot update function");

        bytes4 functionSelector = _data.functionSelector;

        if(IRouterState(defaultFunctions).getFunction(functionSelector).implementation == address(0)) {
            // Check: must not update non-existing function selector.
            require(FunctionManagerStorage.data().allFunctions.contains(functionSelector), "FunctionManager: function does not exist");    
        } else {
            // Check: updating a default function for the first time.
            require(FunctionManagerStorage.data().allFunctions.add(functionSelector), "FunctionManager: function does not exist");    
        }

        require(
                _selectorSignatureMatch(functionSelector, _data.functionSignature),
                "ExtensionState: fn selector and signature mismatch."
            );
        require(_data.implementation != address(0), "FunctionManager: implementation cannot be zero address");

        FunctionManagerStorage.data().functionData[functionSelector] = _data;

        emit FunctionUpdated(functionSelector, _data.implementation, _data);
    }

    function _getFunctionData(bytes4 _functionSelector) internal view virtual override returns (FunctionWithMetadata memory functionWithMetadata) {
        FunctionWithMetadata memory fn = FunctionManagerStorage.data().functionData[_functionSelector];
        return fn.implementation != address(0) ? fn : IRouterState(defaultFunctions).getFunction(_functionSelector);
    }

    /// @dev Returns the implementation address to delegateCall for the given function selector.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        return _getFunctionData(_functionSelector).implementation;
    }
}