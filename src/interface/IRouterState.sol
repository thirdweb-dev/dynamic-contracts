// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title ERC-7504 Dynamic Contracts: IRouterState.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defines an API to expose a router's extensions.

interface IRouterState is IExtension {

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions of the Router.
     *  @return allExtensions An array of all extensions.
     */
    function getAllExtensions() external view returns (Extension[] memory allExtensions);
}