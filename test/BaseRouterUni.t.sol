// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/interface/IExtension.sol";
import "src/presets/BaseRouterUni.sol";
import "./utils/MockContracts.sol";

contract CustomRouter is BaseRouterUni {

    constructor(Extension[] memory _extensions) BaseRouterUni(_extensions) {}

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return true;
    }
}

contract BaseRouterUniTest is Test, IExtension {

    BaseRouterUni internal router;

    Extension internal defaultExtension1;
    Extension internal defaultExtension2;

    uint256 internal defaultExtensionsCount = 2;

    function setUp() public virtual {
        
        // Set metadata
        defaultExtension1.metadata.name = "MultiplyDivide";
        defaultExtension1.metadata.metadataURI = "ipfs://MultiplyDivide";
        defaultExtension1.metadata.implementation = address(new MultiplyDivide());

        defaultExtension2.metadata.name = "AddSubstract";
        defaultExtension2.metadata.metadataURI = "ipfs://AddSubstract";
        defaultExtension2.metadata.implementation = address(new AddSubstract());

        // Set functions

        defaultExtension1.functions.push(ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        ));
        defaultExtension1.functions.push(ExtensionFunction(
            MultiplyDivide.divideNumber.selector,
            "divideNumber(uint256)"
        ));
        defaultExtension2.functions.push(ExtensionFunction(
            AddSubstract.addNumber.selector,
            "addNumber(uint256)"
        ));
        defaultExtension2.functions.push(ExtensionFunction(
            AddSubstract.subtractNumber.selector,
            "subtractNumber(uint256)"
        ));

        Extension[] memory defaultExtensions = new Extension[](2);
        defaultExtensions[0] = defaultExtension1;
        defaultExtensions[1] = defaultExtension2;

        // Deploy BaseRouterUni
        router = BaseRouterUni(payable(address(new CustomRouter(defaultExtensions))));
    }

    /*///////////////////////////////////////////////////////////////
                            Helpers
    //////////////////////////////////////////////////////////////*/

    function _validateExtensionDataOnContract(Extension memory _referenceExtension) internal {

        ExtensionFunction[] memory functions = _referenceExtension.functions;

        for(uint256 i = 0; i < functions.length; i += 1) {

            // Check that the correct implementation address is used.
            assertEq(router.getImplementationForFunction(functions[i].functionSelector), _referenceExtension.metadata.implementation);

            // Check that the metadata is set correctly
            ExtensionMetadata memory metadata = router.getMetadataForFunction(functions[i].functionSelector);
            assertEq(metadata.name, _referenceExtension.metadata.name);
            assertEq(metadata.metadataURI, _referenceExtension.metadata.metadataURI);
            assertEq(metadata.implementation, _referenceExtension.metadata.implementation);
        }

        Extension[] memory extensions = router.getAllExtensions();
        for(uint256 i = 0; i < extensions.length; i += 1) {
            if(
                keccak256(abi.encode(extensions[i].metadata.name)) == keccak256(abi.encode(_referenceExtension.metadata.name))
            ) {
                assertEq(extensions[i].metadata.name, _referenceExtension.metadata.name);
                assertEq(extensions[i].metadata.metadataURI, _referenceExtension.metadata.metadataURI);
                assertEq(extensions[i].metadata.implementation, _referenceExtension.metadata.implementation);
                
                ExtensionFunction[] memory fns = extensions[i].functions;
                assertEq(fns.length, _referenceExtension.functions.length);

                for(uint256 k = 0; k < fns.length; k += 1) {
                    assertEq(fns[k].functionSelector, _referenceExtension.functions[k].functionSelector);
                    assertEq(fns[k].functionSignature, _referenceExtension.functions[k].functionSignature);
                }
            } else {
                continue;
            }
        }

        Extension memory storedExtension = router.getExtension(_referenceExtension.metadata.name);
        assertEq(storedExtension.metadata.name, _referenceExtension.metadata.name);
        assertEq(storedExtension.metadata.metadataURI, _referenceExtension.metadata.metadataURI);
        assertEq(storedExtension.metadata.implementation, _referenceExtension.metadata.implementation);

        assertEq(storedExtension.functions.length, _referenceExtension.functions.length);
        for(uint256 l = 0; l < storedExtension.functions.length; l += 1) {
            assertEq(storedExtension.functions[l].functionSelector, _referenceExtension.functions[l].functionSelector);
            assertEq(storedExtension.functions[l].functionSignature, _referenceExtension.functions[l].functionSignature);
        }

    }

    /*///////////////////////////////////////////////////////////////
                            Default extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Check that default extensions are stored correctly.

    /*///////////////////////////////////////////////////////////////
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Add an new extension.

    /// @notice Revert: add an extension whose name is already used by a default extension.

    /// @notice Revert: add an extension whose name is already used by another non-default extension.

    /// @notice Revert: add an extension with an empty name.

    /// @notice Revert: add an extension with an empty implementation address.

    /// @notice Revert: add an extension with a function selector-signature mismatch.

    /// @notice Revert: add an extension with an empty function signature.

    /// @notice Revert: add an extension with an empty function selector.

    /// @notice Revert: add an extension specifying the same function twice.

    /// @notice Revert: add an extension with a function that already exists in a default extension.

    /// @notice Revert: add an extension with a function that already exists in another non-default extension.

    /*///////////////////////////////////////////////////////////////
                            Replace extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Replace a default extension with a new one.

    /// @notice Replace a non-default extension with a new one.

    /// @notice Revert: replace a non existent extension.

    /// @notice Revert: replace an extension with an empty name.

    /// @notice Revert: replace an extension with an empty implementation address.

    /// @notice Revert: replace an extension with a function selector-signature mismatch.

    /// @notice Revert: replace an extension with an empty function signature.

    /// @notice Revert: replace an extension with an empty function selector.

    /// @notice Revert: replace an extension specifying the same function twice.

    /// @notice Revert: replace an extension with a function that already exists in a default extension.

    /// @notice Revert: replace an extension with a function that already exists in another non-default extension.

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Remove a default extension.

    /// @notice Remove a non-default extension.

    /// @notice Revert: remove a non existent extension.

    /// @notice Revert: remove an extension with an empty name.

    /*///////////////////////////////////////////////////////////////
                    Disabling function in extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Disable a function in a default extension.

    /// @notice Disable a function in a non-default extension.

    /// @notice Disable the receive function.

    /// @notice Revert: disable a function in a non existent extension.

    /// @notice Revert: disable a function in an extension with an empty name.

    /// @notice Revert: disable a function in an extension that does not have that function.

    /*///////////////////////////////////////////////////////////////
                    Enable function in extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable a function in a default extension.

    /// @notice Enable a function in a non-default extension.
    
    /// @notice Enable the receive function.

    /// @notice Revert: enable a function in a non existent extension.

    /// @notice Revert: enable a function in an extension with an empty name.

    /// @notice Revert: enable a function with empty function signature.

    /// @notice Revert: enable a function that already exists in another extension.

    /// @notice Revert: enable a function that already exists in a default extension.

    /*///////////////////////////////////////////////////////////////
                        Scenario tests
    //////////////////////////////////////////////////////////////*/

    /// The following tests are for scenarios that may occur in production use of a base router.

    /// @notice Upgrade a buggy function in a default extension.
    
    /// @notice Upgrade a buggy function in a non-default extension.

    /// @notice Replace 2 out of n functions in a default extension.

    /// @notice Add a new extension; one of its functions overrides a function in a default extension.

    /// @notice Add a new extension; one of its functions overrides a function in a non-default extension.
}