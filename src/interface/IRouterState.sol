// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *	@title ERC-7504 Dynamic Contracts.
 *	NOTE: The ERC-165 identifier for this interface is 0x4a00cc48.
 */
interface RouterState /* is Router */ {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice An extension's metadata.
     *
     *  @param name             The unique name of the extension.
     *  @param metadataURI      The URI where the metadata for the extension lives.
     *  @param implementation   The implementation smart contract address of the extension.
     */
    struct ExtensionMetadata {
        string name;
        string metadataURI;
        address implementation;
    }

    /**
     *  @notice An interface to describe an extension's function.
     *
     *  @param functionSelector    The 4 byte selector of the function.
     *  @param functionSignature   Function signature as a string. E.g. "transfer(address,address,uint256)"
     */
    struct ExtensionFunction {
        bytes4 functionSelector;
        string functionSignature;
    }

    /**
     *  @notice An interface to describe an extension.
     *
     *  @param metadata     The extension's metadata; it's name, metadata URI and implementation contract address.
     *  @param functions    The functions that belong to the extension.
     */
    struct Extension {
        ExtensionMetadata metadata;
        ExtensionFunction[] functions;
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions of the Router.
    function getAllExtensions() external view returns (Extension[] memory allExtensions);
}