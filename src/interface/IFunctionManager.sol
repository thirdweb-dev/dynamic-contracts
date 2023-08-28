// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IRouterState.sol";

interface IFunctionManager is IRouterState {

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event FunctionAdded(bytes4 indexed selector, address indexed implementation, FunctionWithMetadata functionWithMetadata);
    event FunctionUpdated(bytes4 indexed selector, address indexed implementation, FunctionWithMetadata functionWithMetadata);
    event FunctionDeleted(bytes4 indexed selector, FunctionWithMetadata functionWithMetadata);

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    function addFunction(FunctionWithMetadata memory functionWithMetadata) external;
    function addFunctionBatch(FunctionWithMetadata[] memory functions) external;

    function updateFunction(FunctionWithMetadata memory functionWithMetadata) external;
    function updateFunctionBatch(FunctionWithMetadata[] memory functions) external;

    function deleteFunction(bytes4 functionSelector) external;
    function deleteFunctionBatch(bytes4[] memory functionSelector) external;
}
