// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../interface/IRouterState.sol";
import "../lib/FunctionManagerStorage.sol";
import "../lib/EnumerableSet.sol";

contract DefaultFunctions is IRouterState {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(FunctionWithMetadata[] memory _functions) {
        for(uint256 i = 0; i < _functions.length; i++) {
            _addFunction(_functions[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getAllFunctions() public view virtual returns (FunctionWithMetadata[] memory functions) {
        bytes32[] memory allFunctions = FunctionManagerStorage.data().allFunctions.values();
        functions = new FunctionWithMetadata[](allFunctions.length);

        for(uint256 i = 0; i < allFunctions.length; i++) {
            bytes4 functionSelector = bytes4(allFunctions[i]);
            functions[i] = FunctionManagerStorage.data().functionData[functionSelector];
        }
    }

    /// @dev Returns a function of the Router.
    function getFunction(bytes4 _functionSelector) external view returns (FunctionWithMetadata memory functionWithMetadata) {
        functionWithMetadata = _getFunctionData(_functionSelector);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _getFunctionData(bytes4 _functionSelector) internal view virtual returns (FunctionWithMetadata memory functionWithMetadata) {
        functionWithMetadata = FunctionManagerStorage.data().functionData[_functionSelector];
    }

    function _addFunction(FunctionWithMetadata memory _data) internal virtual {
        bytes4 functionSelector = _data.functionSelector;

        // Check: must not re-add existing function selector.
        require(!FunctionManagerStorage.data().allFunctions.add(functionSelector), "FunctionManager: function already exists");
        require(
                _selectorSignatureMatch(functionSelector, _data.functionSignature),
                "ExtensionState: fn selector and signature mismatch."
            );

        FunctionManagerStorage.data().allFunctions.add(functionSelector);
        FunctionManagerStorage.data().functionData[functionSelector] = _data;
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
}