// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Router.sol";
import "./ExtensionManager.sol";

/// @title BaseRouter
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice A preset Router + ExtensionManager.

abstract contract BaseRouter is Router, ExtensionManager {
    
    /**
	 *	@notice Returns the implementation address to delegateCall for the given function selector.
	 *	@param _functionSelector The function selector to get the implementation address for.
	 *	@return implementation The implementation address to delegateCall for the given function selector.
	 */
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getMetadataForFunction(_functionSelector).implementation;
    }
}