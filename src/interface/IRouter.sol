// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-7504 Dynamic Contracts: IRouter.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Routes an incoming call to an appropriate implementation address.
/// @dev Fallback function delegateCalls `getImplementationForFunction(msg.sig)` for a given incoming call.
/// NOTE: The ERC-165 identifier for this interface is 0xce0b6013.

interface IRouter {

	/**
	 *	@notice delegateCalls the appropriate implementation address for the given incoming function call.
	 *	@dev The implementation address to delegateCall MUST be retrieved from calling `getImplementationForFunction` with the
     *       incoming call's function selector.
	 */
	fallback() external payable;

	/*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

	/**
	 *	@notice Returns the implementation address to delegateCall for the given function selector.
	 *	@param _functionSelector The function selector to get the implementation address for.
	 *	@return implementation The implementation address to delegateCall for the given function selector.
	 */
    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address implementation);
}