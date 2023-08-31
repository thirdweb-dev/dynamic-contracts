// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/interface/IExtension.sol";
import "src/presets/BaseRouterWithDefaults.sol";
import "./utils/MockContracts.sol";

contract BaseRouterWithDefaultsTest is Test, IExtension {

    BaseRouterWithDefaults internal router;

    Extension internal defaultExtension1;
    Extension internal defaultExtension2;

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

        // Deploy BaseRouterWithDefaults
        router = new BaseRouterWithDefaults(defaultExtensions);
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
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    // @note add a new extension that already exists as a default.
    function test_revert_addExtension_alreadyExistsAsDefault() public {
        // Create Extension struct
        Extension memory extension = defaultExtension1;

        // Call: addExtension
        vm.expectRevert("BaseRouterWithDefaults: re-adding a default extension.");
        router.addExtension(extension);
    }

    // @note add a new extension with a fn that already exists in a default.
    function test_revert_addExtension_fnAlreadyExistsInDefault() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "MultiplyOnly";
        extension.metadata.metadataURI = "ipfs://MultiplyOnly";
        extension.metadata.implementation = address(new MultiplyDivide());

        // Set functions
        extension.functions = new ExtensionFunction[](1);

        extension.functions[0] = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );
        // Call: addExtension
        vm.expectRevert("ExtensionManager: fn implemented in default extension.");
        router.addExtension(extension);
    }

    // @note: add a new extension
    function test_state_addExtension() public {

        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](3);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );
        extension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.decrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        
        ExtensionMetadata memory metadata1 = router.getMetadataForFunction(IncrementDecrementGet.incrementNumber.selector);
        assertEq(metadata1.name, "");
        assertEq(metadata1.metadataURI, "");
        assertEq(metadata1.implementation, address(0));

        ExtensionMetadata memory metadata2 = router.getMetadataForFunction(IncrementDecrementGet.decrementNumber.selector);
        assertEq(metadata2.name, "");
        assertEq(metadata2.metadataURI, "");
        assertEq(metadata2.implementation, address(0));

        ExtensionMetadata memory metadata3 = router.getMetadataForFunction(IncrementDecrementGet.getNumber.selector);
        assertEq(metadata3.name, "");
        assertEq(metadata3.metadataURI, "");
        assertEq(metadata3.implementation, address(0));

        assertEq(router.getAllExtensions().length, 2); // 2 default extensions

        // Call: addExtension
        router.addExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);
        
        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);
    }

    // @note add a new extension with the receive function.
    function test_state_addExtension_withReceiveFunction() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "Receive";
        extension.metadata.metadataURI = "ipfs://Receive";
        extension.metadata.implementation = address(new Receive());
        
        // Set functions
        extension.functions = new ExtensionFunction[](1);

        extension.functions[0] = ExtensionFunction(
            bytes4(0),
            "receive()"
        );

        // Pre-call checks
        address sender = address(0x123);
        vm.deal(sender, 100 ether);

        vm.expectRevert();
        vm.prank(sender);
        address(router).call{value: 1 ether}("");

        // Call: addExtension
        router.addExtension(extension);
        
        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality

        uint256 balBefore = (address(router)).balance;
        uint256 amount = 1 ether;

        vm.prank(sender);
        address(router).call{value: 1 ether}("");

        assertEq((address(router)).balance, balBefore + amount);
    }

    // @note add a new extension with a function that already exists in another extension.
    function test_revert_addExtension_fnAlreadyExistsInAnotherExtension() public {
        // Create Extension struct
        Extension memory extension1;
        Extension memory extension2;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        extension2.metadata.name = "IncrementDecrementGet";
        extension2.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        extension2.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );
        
        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension1);

        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.addExtension(extension2);
    }

    // @note: add a new extension with a name that is already used by an existing extension.
    function test_revert_addExtension_nameAlreadyUsed() public {
        // Create Extension struct
        Extension memory extension1;
        Extension memory extension2;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        extension2.metadata.name = extension1.metadata.name;
        extension2.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        extension2.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );
        
        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension1);

        vm.expectRevert("ExtensionManager: extension already exists.");
        router.addExtension(extension2);
    }

    // @note add a new extension with an empty name.
    function test_revert_addExtension_emptyName() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: empty name.");
        router.addExtension(extension1);
    }

    // @note add a new extension with an empty implementation address.
    function test_revert_addExtension_emptyImplementation() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(0);   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: adding extension without implementation.");
        router.addExtension(extension1);
    }

    // @note add a new extension with fn selector-signature mismatch.
    function test_revert_addExtension_fnSelectorSignatureMismatch() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "getNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addExtension(extension1);
    }

    // @note add a new extension specifying same function twice.
    function test_revert_addExtension_duplicateFunction() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.addExtension(extension1);
    }

    // @note add a new extension with empty function signature.
    function test_revert_addExtension_emptyFunctionSignature() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            ""
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addExtension(extension1);
    }

    // @note add a new extension with empty function selector.
    function test_revert_addExtension_emptyFunctionSelector() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            bytes4(0),
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addExtension(extension1);
    }

    /*///////////////////////////////////////////////////////////////
                            Replacing extensions
    //////////////////////////////////////////////////////////////*/

    // @note: replace an existing extension; new extension has no functions.
    function test_state_replaceExtension_defaultExtension_noFunctions() public {
        // Create Extension struct
        Extension memory extension;
        extension.metadata = defaultExtension1.metadata;

        // Call: replaceExtension
        router.replaceExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), address(0));

        MultiplyDivide mul = MultiplyDivide(address(router));
        vm.expectRevert("Router: function does not exist.");
        mul.multiplyNumber(25);
    }

    // @note: replace an existing extension; new extension has all same functions.
    function test_state_replaceExtension_defaultExtension_sameFunctions() public { // Create Extension struct
        Extension memory extension = defaultExtension1;
        extension.metadata.metadataURI = "ipfs://MultiplyDivide-new-URI";

        // Call: replaceExtension
        router.replaceExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), extension.metadata.implementation);

        MultiplyDivide mul = MultiplyDivide(address(router));
        
        bytes memory data = abi.encodeWithSelector(MultiplyDivide.multiplyNumber.selector, uint256(25));
        (bool success, bytes memory returnData) = address(router).call(data);
        assertEq(success, true);
    }

    // @note replace an extension; new extension has all new functions.
    function test_state_replaceExtension_defaultExtension_allNewFunctions() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = defaultExtension1.metadata.name;
        extension.metadata.metadataURI = "ipfs://MultiplyDivide-new-URI";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](3);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );
        extension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );


        // Call: replaceExtension
        router.replaceExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality
        MultiplyDivide mul = MultiplyDivide(address(router));
        vm.expectRevert("Router: function does not exist.");
        mul.multiplyNumber(25);
        vm.expectRevert("Router: function does not exist.");
        mul.divideNumber(25);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);
    }

    // @note replace an extension; new extension has some existing functions, some new functions.
    function test_state_replaceExtension_defaultExtension_someNewFunctions() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = defaultExtension1.metadata.name;
        extension.metadata.metadataURI = "ipfs://MultiplyDivide-new-URI";
        extension.metadata.implementation = address(new IncrementDecrementMultiply());

        // Set functions
        extension.functions = new ExtensionFunction[](4);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrement.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrement.decrementNumber.selector,
            "decrementNumber()"
        );
        extension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        extension.functions[3] = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );


        // Call: replaceExtension
        router.replaceExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality
        MultiplyDivide mul = MultiplyDivide(address(router));
        
        vm.expectRevert("Router: function does not exist.");
        mul.divideNumber(25);

        IncrementDecrementMultiply inc = IncrementDecrementMultiply(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.multiplyNumber(25);
        assertEq(inc.getNumber(), 25);
    }

    // @note replace extension with an extension with a fn that already exists in a default.
    function test_revert_replaceExtension_fnAlreadyExistsInDefault() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.implementation = address(new AddSubstract());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            AddSubstract.addNumber.selector,
            "addNumber(uint256)"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: fn implemented in default extension.");
        router.replaceExtension(updatedExtension);
    }

    // @note: replace an existing extension; new extension has no functions.
    function test_state_replaceExtension_noFunctions() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](0);

        // Call: addExtension
        router.replaceExtension(updatedExtension);

        // Post-call checks
        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));

        IncrementDecrement inc = IncrementDecrement(address(router));
        vm.expectRevert("Router: function does not exist.");
        inc.incrementNumber();
    }

    // @note: replace an existing extension; new extension has all same functions.
    function test_state_replaceExtension_sameFunctions() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.metadataURI = "ipfs://IncrementDecrement-new-URI";
        updatedExtension.functions = extension.functions;

        // Call: addExtension
        router.replaceExtension(updatedExtension);

        // Post-call checks
        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(IncrementDecrement.incrementNumber.selector), extension.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrement.decrementNumber.selector), extension.metadata.implementation);
    }

    // @note replace an extension; new extension has all new functions.
    function test_state_replaceExtension_allNewFunctions() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.replaceExtension(updatedExtension);

        // Post-call checks
        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.decrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), updatedExtension.metadata.implementation);

        vm.expectRevert("Router: function does not exist.");
        inc.incrementNumber();
        vm.expectRevert("Router: function does not exist.");
        inc.decrementNumber();

        assertEq(inc.getNumber(), 2);
    }

    // @note replace an extension; new extension has some existing functions, some new functions.
    function test_state_replaceExtension_someNewFunctions() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        
        updatedExtension.functions = new ExtensionFunction[](3);
        updatedExtension.functions[0] = extension.functions[0];
        updatedExtension.functions[1] = extension.functions[1];
        updatedExtension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.replaceExtension(updatedExtension);

        // Post-call checks
        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), updatedExtension.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.decrementNumber.selector), updatedExtension.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), updatedExtension.metadata.implementation);
        
        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();
        inc.incrementNumber();
        inc.decrementNumber();

        assertEq(inc.getNumber(), 2);
    }

    // @note replace extension with an extension with a function that already exists in another extension.
    function test_revert_replaceExtension_fnAlreadyExistsInAnotherExtension() public {
        // Create Extension struct
        Extension memory extension1;
        Extension memory extension2;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        extension2.metadata.name = "IncrementDecrementGet";
        extension2.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        extension2.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension1);
        _validateExtensionDataOnContract(extension1);

        router.addExtension(extension2);
        _validateExtensionDataOnContract(extension2);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension1;

        updatedExtension1.metadata = extension1.metadata;
        updatedExtension1.metadata.implementation = address(new IncrementDecrementGet());
        
        updatedExtension1.functions = new ExtensionFunction[](3);
        updatedExtension1.functions[0] = extension1.functions[0];
        updatedExtension1.functions[1] = extension1.functions[1];
        
        // Already exists in extension2
        updatedExtension1.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.replaceExtension(updatedExtension1);
    }

    // @note replace an extension that does not exist.
    function test_revert_replaceExtension_extensionDoesNotExist() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.replaceExtension(extension);
    }

    // @note replace an extension with an empty name.
    function test_revert_replaceExtension_emptyName() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = "";
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.replaceExtension(updatedExtension);
    }

    // @note replace an extension with an empty implementation address.
    function test_revert_replaceExtension_emptyImplementation() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = extension.metadata.name;
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(0);
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: adding extension without implementation.");
        router.replaceExtension(updatedExtension);
    }

    // @note replace an extension with fn selector-signature mismatch.
    function test_revert_replaceExtension_fnSelectorSignatureMismatch() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = extension.metadata.name;
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "getNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.replaceExtension(updatedExtension);
    }

    // @note replace an extension specifying same function twice.
    function test_revert_replaceExtension_duplicateFunction() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = extension.metadata.name;
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        
        updatedExtension.functions = new ExtensionFunction[](2);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        updatedExtension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.replaceExtension(updatedExtension);
    }

    // @note replace an extension with empty function signature.
    function test_revert_replaceExtension_emptyFunctionSignature() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = extension.metadata.name;
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            ""
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.replaceExtension(updatedExtension);
    }

    // @note replace an extension with empty function selector.
    function test_revert_replaceExtension_emptyFunctionSelector() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));
        inc.incrementNumber();
        inc.incrementNumber();

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata.name = extension.metadata.name;
        updatedExtension.metadata.metadataURI = extension.metadata.metadataURI;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            bytes4(0),
            "getNumber()"
        );

        // Call: replaceExtension
        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.replaceExtension(updatedExtension);
    }

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    // @note remove an overriden default extension.
    function test_state_removeExtension_overriddenDefaultExtension() public {
         // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = defaultExtension1.metadata.name;
        extension.metadata.metadataURI = "ipfs://MultiplyDivide-new-URI";
        extension.metadata.implementation = address(new IncrementDecrementMultiply());

        // Set functions
        extension.functions = new ExtensionFunction[](4);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrement.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrement.decrementNumber.selector,
            "decrementNumber()"
        );
        extension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        extension.functions[3] = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );


        // Call: replaceExtension
        router.replaceExtension(extension);

        // Post-call checks
        _validateExtensionDataOnContract(extension);

        // Verify functionality
        MultiplyDivide mul = MultiplyDivide(address(router));
        vm.expectRevert("Router: function does not exist.");
        mul.divideNumber(25);

        IncrementDecrementMultiply inc = IncrementDecrementMultiply(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.multiplyNumber(25);
        assertEq(inc.getNumber(), 25);

        // Remove overriden version of default extension
        router.removeExtension(defaultExtension1.metadata.name);

        Extension memory currentExtension = defaultExtension1;
        _validateExtensionDataOnContract(currentExtension);
        
        // Verify functionality
        vm.expectRevert("Router: function does not exist.");
        inc.getNumber();
        vm.expectRevert("Router: function does not exist.");
        inc.incrementNumber();
        vm.expectRevert("Router: function does not exist.");
        inc.decrementNumber();

        bytes memory data = abi.encodeWithSelector(MultiplyDivide.divideNumber.selector, 5);
        (bool success, bytes memory returnData) = address(router).call(data);
        assertTrue(success);

        bytes memory data2 = abi.encodeWithSelector(MultiplyDivide.multiplyNumber.selector, 4);
        (bool success2, bytes memory returnData2) = address(router).call(data2);
        assertTrue(success2);
    }

    // @note remove an extension that is a default.
    function test_revert_removeExtension_defaultExtension() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeExtension(defaultExtension1.metadata.name);
    }

    // @note: remove an existing extension.
    function test_state_removeExtension() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.implementation = address(new IncrementDecrementGet());
        
        updatedExtension.functions = new ExtensionFunction[](3);
        updatedExtension.functions[0] = extension.functions[0];
        updatedExtension.functions[1] = extension.functions[1];
        updatedExtension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.replaceExtension(updatedExtension);
        _validateExtensionDataOnContract(updatedExtension);

        // Call: removeExtension

        assertEq(router.getAllExtensions().length, 3);

        router.removeExtension(updatedExtension.metadata.name);
        assertEq(router.getAllExtensions().length, 2);

        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.decrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));

        Extension memory ext = router.getExtension(updatedExtension.metadata.name);
        assertEq(ext.metadata.name, "");
        assertEq(ext.metadata.metadataURI, "");
        assertEq(ext.metadata.implementation, address(0));
        assertEq(ext.functions.length, 0);
    }

    // @note remove an extension that does not exist.
    function test_revert_removeExtension_extensionDoesNotExist() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeExtension("SomeExtension");
    }

    // @note remove an extension with an empty name.
    function test_revert_removeExtension_emptyName() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeExtension("");
    }

    /*///////////////////////////////////////////////////////////////
                        Adding function to extension
    //////////////////////////////////////////////////////////////*/

    // @note add a function to an extension where the function already exists in a default extension.
    function test_revert_addFunctionToExtension_functionAlreadyExistsInDefault() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementMultiply());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Add function to extension
        ExtensionFunction memory fn = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );
        vm.expectRevert("ExtensionManager: fn implemented in default extension.");
        router.addFunctionToExtension(extension.metadata.name, fn);
    }

    // @note add a function to a default extension.
    function test_revert_addFunctionToExtension_defaultExtension() public {
        // Add function to extension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.addFunctionToExtension(defaultExtension1.metadata.name, fn);
    }

    // @note: add a new function to an existing extension.
    function test_state_addFunctionToExtension() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        router.addFunctionToExtension(extension.metadata.name, fn);

        // Post call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 3);

        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](3);
        updatedExtension.functions[0] = extension.functions[0];
        updatedExtension.functions[1] = extension.functions[1];
        updatedExtension.functions[2] = fn;

        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        IncrementDecrementGet inc = IncrementDecrementGet(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);
        
        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);
    }

    // @note add a receive function to an extension
    function test_state_addFunctionToExtension_receiveFunction() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrementReceive";
        extension.metadata.metadataURI = "ipfs://IncrementDecrementReceive";
        extension.metadata.implementation = address(new IncrementDecrementReceive());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementReceive.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementReceive.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(bytes4(0)), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        address sender = address(0x123);
        vm.deal(sender, 100 ether);

        vm.expectRevert();
        vm.prank(sender);
        address(router).call{value: 1 ether}("");

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            bytes4(0),
            "receive()"
        );
        router.addFunctionToExtension(extension.metadata.name, fn);

        // Post call checks
        assertEq(router.getImplementationForFunction(bytes4(0)), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 3);

        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](3);
        updatedExtension.functions[0] = extension.functions[0];
        updatedExtension.functions[1] = extension.functions[1];
        updatedExtension.functions[2] = fn;

        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        uint256 balBefore = (address(router)).balance;
        uint256 amount = 1 ether;

        vm.prank(sender);
        address(router).call{value: 1 ether}("");

        assertEq((address(router)).balance, balBefore + amount);
    }

    // @note add a function to an extension that does not exist.
    function test_revert_addFunctionToExtension_extensionDoesNotExist() public {
        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.addFunctionToExtension("SomeExtension", fn);
    }

    // @note add a function to an extension which already has the function.
    function test_revert_addFunctionToExtension_functionAlreadyExistsInExtension() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = extension.functions[0];
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.addFunctionToExtension(extension.metadata.name, fn);
    }

    // @note add a function to an extension, but another extension already has that function.
    function test_revert_addFunctionToExtension_functionAlreadyExistsInAnotherExtension() public {
        // Create Extension struct
        Extension memory extension1;
        Extension memory extension2;

        // Set metadata
        extension1.metadata.name = "IncrementDecrement";
        extension1.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension1.metadata.implementation = address(new IncrementDecrement());   

        extension2.metadata.name = "IncrementDecrementGet";
        extension2.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        extension2.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension1.functions = new ExtensionFunction[](2);
        extension1.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension1.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );
        
        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension1);
        router.addExtension(extension2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.addFunctionToExtension(extension1.metadata.name, fn);
    }

    // @note add a function to an extension with an empty function signature.
    function test_revert_addFunctionToExtension_emptyFunctionSignature() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            ""
        );

        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addFunctionToExtension(extension.metadata.name, fn);
    }

    // @note add a function to an extension with an empty function selector.
    function test_revert_addFunctionToExtension_emptyFunctionSelector() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            bytes4(0),
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addFunctionToExtension(extension.metadata.name, fn);
    }

    // @note add a function to an extension with fn selector-signature mismatch.
    function test_revert_addFunctionToExtension_fnSelectorSignatureMismatch() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: addFunctionToExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "incrementNumber()"
        );

        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.addFunctionToExtension(extension.metadata.name, fn);
    }


    /*///////////////////////////////////////////////////////////////
                    Removing function from extension
    //////////////////////////////////////////////////////////////*/

    // @note remove a function from non-default extension, where the extension's default version still has that function.
    function test_state_removeFunctionFromExtension_functionStillExistsInDefault() public {
        // Create Extension struct
        Extension memory extension = defaultExtension1;
        extension.metadata.implementation = address(new MultiplyDivideGet());

        // Call: replaceExtension
        router.replaceExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre call checks
        assertEq(router.getImplementationForFunction(MultiplyDivideGet.multiplyNumber.selector), extension.metadata.implementation);

        // Call: removeFunctionFromExtension
        router.removeFunctionFromExtension(extension.metadata.name, MultiplyDivideGet.multiplyNumber.selector);

        // Post call checks
        assertEq(router.getImplementationForFunction(MultiplyDivideGet.multiplyNumber.selector), address(0));

        MultiplyDivideGet mul = MultiplyDivideGet(address(router));
        vm.expectRevert("Router: function does not exist.");
        mul.multiplyNumber(25);
    }

    // @note remove a function from a default extension.
    function test_revert_removeFunctionFromExtension_defaultExtension() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeFunctionFromExtension(defaultExtension1.metadata.name, MultiplyDivide.multiplyNumber.selector);
    }

    // @note remove a function from an existing extension.
    function test_state_removeFunctionFromExtension() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: removeFunctionFromExtension
        router.removeFunctionFromExtension(extension.metadata.name, IncrementDecrementGet.incrementNumber.selector);

        // Post call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 1);

        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = extension.functions[1];

        _validateExtensionDataOnContract(updatedExtension);
    }

    // @note remove a receive function from an existing extension.
    function test_state_removeFunctionFromExtension_receiveFunction() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrementReceive";
        extension.metadata.metadataURI = "ipfs://IncrementDecrementReceive";
        extension.metadata.implementation = address(new IncrementDecrementReceive());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            bytes4(0),
            "receive()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        address sender = address(0x123);
        vm.deal(sender, 100 ether);

        uint256 balBefore = (address(router)).balance;
        uint256 amount = 1 ether;

        vm.prank(sender);
        address(router).call{value: 1 ether}("");

        assertEq((address(router)).balance, balBefore + amount);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(bytes4(0)), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: removeFunctionFromExtension
        router.removeFunctionFromExtension(extension.metadata.name, bytes4(0));

        // Post call checks
        assertEq(router.getImplementationForFunction(bytes4(0)), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 1);

        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = extension.functions[1];

        _validateExtensionDataOnContract(updatedExtension);

        vm.expectRevert();
        vm.prank(sender);
        address(router).call{value: 1 ether}("");
    }

    // @note remove a function from an extension that does not exist.
    function test_revert_removeFunctionFromExtension_extensionDoesNotExist() public {
        // Call: removeFunctionFromExtension
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeFunctionFromExtension("", IncrementDecrementGet.incrementNumber.selector);
    }

    // @note remove a function from an extension which does not have the function.
    function test_revert_removeFunctionFromExtension_functionDoesNotExistInExtension() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: removeFunctionFromExtension
        vm.expectRevert("ExtensionManager: incorrect extension.");
        router.removeFunctionFromExtension(extension.metadata.name, IncrementDecrementGet.getNumber.selector);
    }

    // @note remove a function from an extension but the function exists in another extension.
    function test_revert_removeFunctionFromExtension_functionExistsInAnotherExtension() public {
        // Create Extension struct
        Extension memory extension;
        Extension memory differentExtension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        differentExtension.metadata.name = "IncrementDecrementGet";
        differentExtension.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        differentExtension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        differentExtension.functions = new ExtensionFunction[](1);
        differentExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        router.addExtension(differentExtension);
        _validateExtensionDataOnContract(differentExtension);

        // Call: removeFunctionFromExtension
        vm.expectRevert("ExtensionManager: incorrect extension.");
        router.removeFunctionFromExtension(extension.metadata.name, IncrementDecrementGet.getNumber.selector);
    }

    // @note remove a function (other than receive function) from an extension with an empty function selector.
    function test_revert_removeFunctionFromExtension_emptyFunctionSelector() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions
        extension.functions = new ExtensionFunction[](2);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Pre-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), extension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, 2);

        // Call: removeFunctionFromExtension
        vm.expectRevert("ExtensionManager: incorrect extension.");
        router.removeFunctionFromExtension(extension.metadata.name, bytes4(0));
    }

    /*///////////////////////////////////////////////////////////////
                            Scenario tests
    //////////////////////////////////////////////////////////////*/

    // @note: scenario: Update a buggy function by setting a new implementation for it.
    function test_scenario_updateBuggyFunction() public {
        // Create Extension struct
        Extension memory extension;
        
        // Set metadata
        extension.metadata.name = "IncrementDecrementGetBug";
        extension.metadata.metadataURI = "ipfs://IncrementDecrementGetBug";
        extension.metadata.implementation = address(new IncrementDecrementGetBug());

        // Set functions
        extension.functions = new ExtensionFunction[](3);

        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGetBug.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGetBug.decrementNumber.selector,
            "decrementNumber()"
        );
        extension.functions[2] = ExtensionFunction(
            IncrementDecrementGetBug.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Update buggy `decrementNumber` function.

        IncrementDecrementGet inc = IncrementDecrementGet(address(router));

        assertEq(inc.getNumber(), 0);

        inc.incrementNumber();
        assertEq(inc.getNumber(), 1);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 2); // !!! BUG !!!

        
        // 1. Remove buggy function from current extension.
        router.removeFunctionFromExtension(extension.metadata.name, IncrementDecrementGetBug.decrementNumber.selector);
        // 2. Add fixed function as part of a new extension.
        Extension memory newExtension;
        newExtension.metadata.name = "DecrementFixed";
        newExtension.metadata.metadataURI = "ipfs://DecrementFixed";
        newExtension.metadata.implementation = address(new DecrementFixed());

        newExtension.functions = new ExtensionFunction[](1);
        newExtension.functions[0] = ExtensionFunction(
            DecrementFixed.decrementNumber.selector,
            "decrementNumber()"
        );

        router.addExtension(newExtension);
        _validateExtensionDataOnContract(newExtension);

        assertEq(inc.getNumber(), 2);

        inc.decrementNumber();
        assertEq(inc.getNumber(), 1);
    }

    // @note: scenario: Rollback a buggy update to a function.
    function test_scenario_rollbackBuggyFunctionUpdate() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // 1. Add extension with `incrementNumber` and `decrementNumber` functions.
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtensionWithBug;

        updatedExtensionWithBug.metadata.name = extension.metadata.name;
        updatedExtensionWithBug.metadata.metadataURI = "ipfs://IncrementDecrementGetBug";
        updatedExtensionWithBug.metadata.implementation = address(new IncrementDecrementGetBug());
        updatedExtensionWithBug.functions = extension.functions;

        // 2. Replace extension; the `decrementNumber` function is buggy.
        router.replaceExtension(updatedExtensionWithBug);
        _validateExtensionDataOnContract(updatedExtensionWithBug);

        // 3. Remove the buggy function from the update.
        router.removeFunctionFromExtension(extension.metadata.name, IncrementDecrementGet.decrementNumber.selector);

        // 4. Add fixed function as part of a new extension.
        Extension memory newExtension;
        newExtension.metadata.name = "DecrementFixed";
        newExtension.metadata.metadataURI = "ipfs://DecrementFixed";
        newExtension.metadata.implementation = address(new DecrementFixed());

        newExtension.functions = new ExtensionFunction[](1);
        newExtension.functions[0] = ExtensionFunction(
            DecrementFixed.decrementNumber.selector,
            "decrementNumber()"
        );

        router.addExtension(newExtension);

        // Post-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrement.incrementNumber.selector), updatedExtensionWithBug.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrement.decrementNumber.selector), newExtension.metadata.implementation);
    }

    // @note scenario: Upgrade an extension, update includes a bug, update the entire extension again.
    function test_scenario_upgradeIncludesBug() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrement());   

        // Set functions
        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        extension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.decrementNumber.selector,
            "decrementNumber()"
        );

        // 1. Add extension with `incrementNumber` and `decrementNumber` functions.
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtensionWithBug;

        updatedExtensionWithBug.metadata.name = extension.metadata.name;
        updatedExtensionWithBug.metadata.metadataURI = "ipfs://IncrementDecrementGetBug";
        updatedExtensionWithBug.metadata.implementation = address(new IncrementDecrementGetBug());
        updatedExtensionWithBug.functions = extension.functions;

        // 2. Replace extension; the `decrementNumber` function is buggy.
        router.replaceExtension(updatedExtensionWithBug);
        _validateExtensionDataOnContract(updatedExtensionWithBug);

        // 4. Replace extension; the `decrementNumber` function is now fixed.
        Extension memory updatedExtensionWithoutBug;
        updatedExtensionWithoutBug.metadata = updatedExtensionWithBug.metadata;
        updatedExtensionWithoutBug.metadata.implementation = address(new IncrementDecrementGet());

        updatedExtensionWithoutBug.functions = updatedExtensionWithBug.functions;

        router.replaceExtension(updatedExtensionWithoutBug);

        // Post-call checks
        assertEq(router.getImplementationForFunction(IncrementDecrement.incrementNumber.selector), updatedExtensionWithoutBug.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrement.decrementNumber.selector), updatedExtensionWithoutBug.metadata.implementation);
    }
}