// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IRouter.sol";

/// @title ERC-7504 Dynamic Contracts: Router.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Routes an incoming call to an appropriate implementation address.

abstract contract Router is IRouter {

    /**
	 *	@notice delegateCalls the appropriate implementation address for the given incoming function call.
	 *	@dev The implementation address to delegateCall MUST be retrieved from calling `getImplementationForFunction` with the
     *       incoming call's function selector.
	 */
    fallback() external payable virtual {
        if(msg.data.length == 0) return;
        
        address implementation = getImplementationForFunction(msg.sig);
        require(implementation != address(0), "Router: function does not exist.");
        _delegate(implementation);
    }

    /// @dev delegateCalls an `implementation` smart contract.
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
	 *	@notice Returns the implementation address to delegateCall for the given function selector.
	 *	@param _functionSelector The function selector to get the implementation address for.
	 *	@return implementation The implementation address to delegateCall for the given function selector.
	 */
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address implementation);
}