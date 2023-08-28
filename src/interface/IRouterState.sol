// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";
import "./IExtension.sol";

/**
 *	@title ERC-7504 Dynamic Contracts.
 *	NOTE: The ERC-165 identifier for this interface is 0x4a00cc48.
 */
interface IRouterState is IExtension {

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions of the Router.
    function getAllExtensions() external view returns (Extension[] memory allExtensions);
}