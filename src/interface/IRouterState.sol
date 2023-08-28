// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";

/**
 *	@title ERC-7504 Dynamic Contracts.
 *	NOTE: The ERC-165 identifier for this interface is 0x4a00cc48.
 */
interface IRouterState {

    /*///////////////////////////////////////////////////////////////
                                Struct
    //////////////////////////////////////////////////////////////*/

    struct FunctionWithMetadata {
        string metadataURI;
        address implementation;
        bytes4 functionSelector;
        string functionSignature;
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns a function of the Router.
    function getFunction(bytes4 _functionSelector) external view returns (FunctionWithMetadata memory functionWithMetadata);

    /// @dev Returns all functions of the Router.
    function getAllFunctions() external view returns (FunctionWithMetadata[] memory allFunctions);
}