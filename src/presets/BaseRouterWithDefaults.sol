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

    function _getFunctionData(bytes4 _functionSelector) internal view virtual override returns (FunctionWithMetadata memory functionWithMetadata) {
        FunctionWithMetadata memory fn = FunctionManagerStorage.data().functionData[_functionSelector];
        return fn.implementation != address(0) ? fn : IRouterState(defaultFunctions).getFunction(_functionSelector);
    }

    /// @dev Returns the implementation address to delegateCall for the given function selector.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        return _getFunctionData(_functionSelector).implementation;
    }
}