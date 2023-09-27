// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "lib/sstore2/contracts/SSTORE2.sol";

import "src/interface/IExtension.sol";
import "src/presets/BaseRouter.sol";
import "./utils/MockContracts.sol";
import "./utils/Strings.sol";

/// @dev This custom router is written only for testing purposes and must not be used in production.
contract CustomRouter is BaseRouter {

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {}

    function initialize() public {
        __BaseRouter_init();
    }

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return true;
    }
}

contract BaseRouterTest is Test, IExtension {
    
    using Strings for uint256;

    BaseRouter internal router;

    Extension internal defaultExtension1;
    Extension internal defaultExtension2;
    Extension internal defaultExtension3;
    Extension internal defaultExtension4;
    Extension internal defaultExtension5;

    uint256 internal defaultExtensionsCount = 2;

    function setUp() public virtual {
        
        // Set metadata
        defaultExtension1.metadata.name = "MultiplyDivide";
        defaultExtension1.metadata.metadataURI = "ipfs://MultiplyDivide";
        defaultExtension1.metadata.implementation = address(new MultiplyDivide());

        defaultExtension2.metadata.name = "AddSubstract";
        defaultExtension2.metadata.metadataURI = "ipfs://AddSubstract";
        defaultExtension2.metadata.implementation = address(new AddSubstract());

        defaultExtension3.metadata.name = "RandomExtension";
        defaultExtension3.metadata.metadataURI = "ipfs://RandomExtension";
        defaultExtension3.metadata.implementation = address(0x3456);

        defaultExtension4.metadata.name = "RandomExtension2";
        defaultExtension4.metadata.metadataURI = "ipfs://RandomExtension2";
        defaultExtension4.metadata.implementation = address(0x5678);

        defaultExtension5.metadata.name = "RandomExtension3";
        defaultExtension5.metadata.metadataURI = "ipfs://RandomExtension3";
        defaultExtension5.metadata.implementation = address(0x7890);

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

        for(uint256 i = 0; i < 10; i++) {
            string memory functionSignature = string(abi.encodePacked("randomFunction", i.toString(), "(uint256)"));
            bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
            defaultExtension3.functions.push(ExtensionFunction(
                selector,
                functionSignature
            ));
        }

        for(uint256 i = 0; i < 20; i++) {
            string memory functionSignature = string(abi.encodePacked("randomFunctionNew", i.toString(), "(uint256,string,bytes,(uint256,uint256,bool))"));
            bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
            defaultExtension4.functions.push(ExtensionFunction(
                selector,
                functionSignature
            ));
        }

        for(uint256 i = 0; i < 30; i++) {
            string memory functionSignature = string(abi.encodePacked("randomFunctionAnother", i.toString(), "(uint256,string,address[])"));
            bytes4 selector = bytes4(keccak256(bytes(functionSignature)));
            defaultExtension5.functions.push(ExtensionFunction(
                selector,
                functionSignature
            ));
        }

        Extension[] memory defaultExtensions = new Extension[](2);
        defaultExtensions[0] = defaultExtension1;
        defaultExtensions[1] = defaultExtension2;

        // Deploy BaseRouter
        router = BaseRouter(payable(address(new CustomRouter(defaultExtensions))));
        CustomRouter(payable(address(router))).initialize();
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
    function test_state_defaultExtensions() public {
        Extension[] memory extensions = router.getAllExtensions();
        assertEq(extensions.length, defaultExtensionsCount);

        _validateExtensionDataOnContract(defaultExtension1);
        _validateExtensionDataOnContract(defaultExtension2);
    }

    /*///////////////////////////////////////////////////////////////
                Deploy / Initialze BaseRouter & SSTORE2
    //////////////////////////////////////////////////////////////*/

    /// @notice Check with a single extension with 10 functions
    function test_state_deployBaseRouter() external {
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);

        uint256 size;
        address defaultExtensionsAddress = routerNew.defaultExtensions();

        assembly {
            size := extcodesize(defaultExtensionsAddress)
        }

        console.log(size);
        // ensure size of default extension contract doesn't breach the limit
        assertTrue(size < 24575);

        bytes memory data = SSTORE2.read(defaultExtensionsAddress);
        Extension[] memory defaults = abi.decode(data, (Extension[]));
        assertEq(defaults.length, defaultExtensionsNew.length);
        for(uint256 i = 0; i < defaults.length; i++) {
            assertEq(defaults[i].functions.length, defaultExtensionsNew[i].functions.length);

            for(uint256 j = 0; j < defaults[i].functions.length; j++) {
                assertEq(defaults[i].functions[j].functionSelector, defaultExtensionsNew[i].functions[j].functionSelector);
            }
        }
    }

    /// @notice Check with multiple extensions extension with ~50 functions in total
    function test_state_deployBaseRouter_multipleExtensions() external {
        Extension[] memory defaultExtensionsNew = new Extension[](3);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension4;
        defaultExtensionsNew[2] = defaultExtension5;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);

        uint256 size;
        address defaultExtensionsAddress = routerNew.defaultExtensions();

        assembly {
            size := extcodesize(defaultExtensionsAddress)
        }

        console.log(size);
        // ensure size of default extension contract doesn't breach the limit
        assertTrue(size < 24575);

        bytes memory data = SSTORE2.read(defaultExtensionsAddress);
        Extension[] memory defaults = abi.decode(data, (Extension[]));
        assertEq(defaults.length, defaultExtensionsNew.length);
        for(uint256 i = 0; i < defaults.length; i++) {
            assertEq(defaults[i].functions.length, defaultExtensionsNew[i].functions.length);

            for(uint256 j = 0; j < defaults[i].functions.length; j++) {
                assertEq(defaults[i].functions[j].functionSelector, defaultExtensionsNew[i].functions[j].functionSelector);
            }
        }
    }

    /// @notice Two default extensions share the same name.
    function test_revert_deployBaesRouter_nameAlreadyUsed() external {
        Extension[] memory defaultExtensionsNew = new Extension[](2);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension3;
        vm.expectRevert("BaseRouter: invalid extension.");
        new CustomRouter(defaultExtensionsNew);
    }

    /// @notice The same function exists in two default extensions.
    function test_revert_deployBaesRouter_fnAlreadyExists() external {
        Extension[] memory defaultExtensionsNew = new Extension[](2);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension4;

        defaultExtensionsNew[1].functions[0] = defaultExtension3.functions[0];

        vm.expectRevert("BaseRouter: invalid extension.");
        new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Default extension has empty name.
    function test_revert_deployBaesRouter_emptyName() external {
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[0].metadata.name = "";

        vm.expectRevert("BaseRouter: invalid extension.");
        new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Default extension has empty implementation address.
    function test_revert_deployBaesRouter_emptyImplementation() external {
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[0].metadata.implementation = address(0);

        vm.expectRevert("BaseRouter: invalid extension.");
        new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Default extension has function selector signature mismatch.
    function test_revert_deployBaesRouter_fnSelectorSignatureMismatch() external {
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[0].functions[0].functionSignature = "whatever(uint256)";

        vm.expectRevert("BaseRouter: invalid extension.");
        new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Check with a single extension with 10 functions
    function test_state_initializeBaseRouter_singleExtension() external {
        // vm.pauseGasMetering();
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
        // vm.resumeGasMetering();

        routerNew.initialize();

        Extension[] memory defaultExtensionsAfterInit = routerNew.getAllExtensions();
        assertEq(defaultExtensionsAfterInit.length, defaultExtensionsNew.length);
        for(uint256 i = 0; i < defaultExtensionsAfterInit.length; i++) {
            assertEq(defaultExtensionsAfterInit[i].functions.length, defaultExtensionsNew[i].functions.length);

            for(uint256 j = 0; j < defaultExtensionsAfterInit[i].functions.length; j++) {
                assertEq(defaultExtensionsAfterInit[i].functions[j].functionSelector, defaultExtensionsNew[i].functions[j].functionSelector);
            }
        }
    }

    /// @notice Check with multiple extensions extension with 50-100 functions in total
    function test_state_initializeBaseRouter_multipleExtensions() external {
        // vm.pauseGasMetering();
        Extension[] memory defaultExtensionsNew = new Extension[](3);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension4;
        defaultExtensionsNew[2] = defaultExtension5;
        
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
        // vm.resumeGasMetering();

        routerNew.initialize();

        Extension[] memory defaultExtensionsAfterInit = routerNew.getAllExtensions();
        assertEq(defaultExtensionsAfterInit.length, defaultExtensionsNew.length);
        for(uint256 i = 0; i < defaultExtensionsAfterInit.length; i++) {
            assertEq(defaultExtensionsAfterInit[i].functions.length, defaultExtensionsNew[i].functions.length);

            for(uint256 j = 0; j < defaultExtensionsAfterInit[i].functions.length; j++) {
                assertEq(defaultExtensionsAfterInit[i].functions[j].functionSelector, defaultExtensionsNew[i].functions[j].functionSelector);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Add an new extension.
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

        assertEq(router.getAllExtensions().length, defaultExtensionsCount);

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

    /// @notice Add an extension with the receive function.
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

    /// @notice Revert: add an extension whose name is already used by a default extension.
    function test_revert_addExtension_nameAlreadyUsedByDefaultExtension() public {
        // Create Extension struct
        Extension memory extension1;

        // Set metadata
        extension1.metadata.name = defaultExtension1.metadata.name;
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
        vm.expectRevert("ExtensionManager: extension already exists.");
        router.addExtension(extension1);
    }
    

    /// @notice Revert: add an extension whose name is already used by another non-default extension.
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

    /// @notice Revert: add an extension with an empty name.
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

    /// @notice Revert: add an extension with an empty implementation address.
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

    /// @notice Revert: add an extension with a function selector-signature mismatch.
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

    /// @notice Revert: add an extension with an empty function signature.
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

    /// @notice Revert: add an extension with an empty function selector.
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

    /// @notice Revert: add an extension specifying the same function twice.
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

    /// @notice Revert: add an extension with a function that already exists in a default extension.
    function test_revert_addExtension_fnAlreadyExistsInDefaultExtension() public {
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
        extension1.functions[1] = defaultExtension1.functions[0];

        // Call: addExtension
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.addExtension(extension1);

        // vm.expectRevert("BaseRouter: function impl already exists.");
        // router.addExtension(extension1);
    }

    /// @notice Revert: add an extension with a function that already exists in another non-default extension.
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

    /*///////////////////////////////////////////////////////////////
                            Replace extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Replace a default extension with a new one.
    function test_state_replaceExtension_defaultExtension() public {
        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        updatedExtension.metadata = defaultExtension1.metadata;
        updatedExtension.metadata.implementation = address(new IncrementDecrementMultiply());
        
        updatedExtension.functions = new ExtensionFunction[](3);
        updatedExtension.functions[0] = defaultExtension1.functions[0];
        updatedExtension.functions[1] = ExtensionFunction(
            IncrementDecrementGet.incrementNumber.selector,
            "incrementNumber()"
        );
        updatedExtension.functions[2] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.replaceExtension(updatedExtension);

        // Post-call checks
        _validateExtensionDataOnContract(updatedExtension);

        // Verify functionality
        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), updatedExtension.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), updatedExtension.metadata.implementation);
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), updatedExtension.metadata.implementation);
        
        IncrementDecrementMultiply inc = IncrementDecrementMultiply(address(router));
        inc.incrementNumber();
        inc.incrementNumber();
        assertEq(inc.getNumber(), 2);


        inc.multiplyNumber(2);
        assertEq(inc.getNumber(), 4);

        vm.expectRevert("Router: function does not exist.");
        MultiplyDivide(address(router)).divideNumber(2);
    }

    

    /// @notice Replace a non-default extension with a new one.
    function test_state_replaceExtension() public {
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


    /// @notice Revert: replace a non existent extension.
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

    /// @notice Revert: replace an extension with an empty name.
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

    /// @notice Revert: replace an extension with an empty implementation address.
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

    /// @notice Revert: replace an extension with a function selector-signature mismatch.
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

    /// @notice Revert: replace an extension with an empty function signature.
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

    /// @notice Revert: replace an extension with an empty function selector.
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

    /// @notice Revert: replace an extension specifying the same function twice.
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

    /// @notice Revert: replace an extension with a function that already exists in a default extension.
    function test_revert_replaceExtension_fnAlreadyExistsInDefaultExtension() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrementGet";
        extension.metadata.metadataURI = "ipfs://IncrementDecrementGet";
        extension.metadata.implementation = address(new IncrementDecrementGet());

        // Set functions

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(extension);
        _validateExtensionDataOnContract(extension);

        // Create Extension struct to replace existing extension
        Extension memory updatedExtension;

        // Set metadata
        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.implementation = address(new IncrementDecrementMultiply());
        
        updatedExtension.functions = new ExtensionFunction[](2);
        updatedExtension.functions[0] = extension.functions[0];
        updatedExtension.functions[1] = defaultExtension1.functions[0];

        // Call: addExtension
        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.replaceExtension(updatedExtension);
    }

    /// @notice Revert: replace an extension with a function that already exists in another non-default extension.
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

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Remove a default extension.
    function test_state_removeExtension_defautlExtension() public {
        // Call: removeExtension

        assertEq(router.getAllExtensions().length, defaultExtensionsCount);

        router.removeExtension(defaultExtension1.metadata.name);
        assertEq(router.getAllExtensions().length, defaultExtensionsCount - 1);

        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(MultiplyDivide.divideNumber.selector), address(0));

        Extension memory ext = router.getExtension(defaultExtension1.metadata.name);
        assertEq(ext.metadata.name, "");
        assertEq(ext.metadata.metadataURI, "");
        assertEq(ext.metadata.implementation, address(0));
        assertEq(ext.functions.length, 0);
    }

    /// @notice Remove a non-default extension.
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

        // Call: replaceExtension
        router.replaceExtension(updatedExtension);
        _validateExtensionDataOnContract(updatedExtension);

        // Call: removeExtension
        assertEq(router.getAllExtensions().length, defaultExtensionsCount + 1);

        router.removeExtension(updatedExtension.metadata.name);
        assertEq(router.getAllExtensions().length, defaultExtensionsCount);

        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.decrementNumber.selector), address(0));
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));

        Extension memory ext = router.getExtension(updatedExtension.metadata.name);
        assertEq(ext.metadata.name, "");
        assertEq(ext.metadata.metadataURI, "");
        assertEq(ext.metadata.implementation, address(0));
        assertEq(ext.functions.length, 0);
    }

    /// @notice Revert: remove a non existent extension.
    function test_revert_removeExtension_extensionDoesNotExist() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeExtension("SomeExtension");
    }

    /// @notice Revert: remove an extension with an empty name.
    function test_revert_removeExtension_emptyName() public {
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.removeExtension("");
    }

    /*///////////////////////////////////////////////////////////////
                    Disabling function in extension
    //////////////////////////////////////////////////////////////*/

    /// @notice Disable a function in a default extension.
    function test_state_disableFunctionInExtension_defaultExtension() public {

        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);

        // Post call checks
        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), address(0));
        assertEq(router.getExtension(defaultExtension1.metadata.name).functions.length, 1);

        Extension memory updatedExtension;
        updatedExtension.metadata = defaultExtension1.metadata;
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = defaultExtension1.functions[1];

        _validateExtensionDataOnContract(updatedExtension);
    }

    /// @notice Disable a function in a non-default extension.
    function test_state_disableFunctionInExtension() public {
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

        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(extension.metadata.name, IncrementDecrementGet.incrementNumber.selector);

        // Post call checks
        assertEq(router.getImplementationForFunction(IncrementDecrementGet.incrementNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, 1);

        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = extension.functions[1];

        _validateExtensionDataOnContract(updatedExtension);
    }

    /// @notice Disable the receive function.
    function test_state_disableFunctionInExtension_receiveFunction() public {
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

        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(extension.metadata.name, bytes4(0));

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

    /// @notice Revert: disable a function in a non existent extension.
    function test_revert_disableFunctionInExtension_extensionDoesNotExist() public {
        // Call: disableFunctionInExtension
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.disableFunctionInExtension("SomeExtension", IncrementDecrementGet.incrementNumber.selector);
    }

    /// @notice Revert: disable a function in an extension with an empty name.
    function test_revert_disableFunctionInExtension_emptyName() public {
        // Call: disableFunctionInExtension
        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.disableFunctionInExtension("", IncrementDecrementGet.incrementNumber.selector);
    }

    /// @notice Revert: disable a function in an extension that does not have that function.
    function test_revert_disableFunctionInExtension_functionDoesNotExistInExtension() public {
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

        // Call: disableFunctionInExtension
        vm.expectRevert("ExtensionManager: incorrect extension.");
        router.disableFunctionInExtension(extension.metadata.name, IncrementDecrementGet.getNumber.selector);
    }

    /*///////////////////////////////////////////////////////////////
                    Enable function in extension
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable a function in a default extension.
    function test_state_enableFunctionInExtension_defaultExtension() public {
        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);

        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), address(0));
        assertEq(router.getExtension(defaultExtension1.metadata.name).functions.length, defaultExtension1.functions.length - 1);

        // Call: enableFunctionInExtension
        router.enableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0]);

        // Post call checks
        assertEq(router.getImplementationForFunction(defaultExtension1.functions[0].functionSelector), defaultExtension1.metadata.implementation);
        assertEq(router.getExtension(defaultExtension1.metadata.name).functions.length, defaultExtension1.functions.length);

        Extension memory updatedExtension;
        updatedExtension.metadata = defaultExtension1.metadata;
        updatedExtension.functions = new ExtensionFunction[](2);
        updatedExtension.functions[0] = defaultExtension1.functions[1];
        updatedExtension.functions[1] = defaultExtension1.functions[0];

        _validateExtensionDataOnContract(updatedExtension);
    }

    /// @notice Enable a function in a non-default extension.
    function test_state_enableFunctionInExtension() public {
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        router.enableFunctionInExtension(extension.metadata.name, fn);

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
    
    /// @notice Enable the receive function.
    function test_state_enableFunctionInExtension_receiveFunction() public {
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            bytes4(0),
            "receive()"
        );
        router.enableFunctionInExtension(extension.metadata.name, fn);

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

    /// @notice Revert: enable a function in a non existent extension.
    function test_revert_enableFunctionInExtension_extensionDoesNotExist() public {
        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.enableFunctionInExtension("SomeExtension", fn);
    }

    /// @notice Revert: enable a function in an extension with an empty name.
    function test_revert_enableFunctionInExtension_emptyName() public {
        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: extension does not exist.");
        router.enableFunctionInExtension("", fn);
    }

    /// @notice Revert: enable a function with empty function signature.
    function test_revert_enableFunctionInExtension_emptyFunctionSignature() public {
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            ""
        );

        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.enableFunctionInExtension(extension.metadata.name, fn);
    }

    /// @notice Revert: enable a function with empty function selector.
    function test_revert_enableFunctionInExtension_emptyFunctionSelector() public {
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            bytes4(0),
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: fn selector and signature mismatch.");
        router.enableFunctionInExtension(extension.metadata.name, fn);
    }

    /// @notice Revert: enable a function that already exists in another extension.
    function test_revert_enableFunctionInExtension_functionAlreadyExistsInAnotherExtension() public {
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.enableFunctionInExtension(extension1.metadata.name, fn);
    }

    /// @notice Revert: enable a function that already exists in a default extension.
    function test_revert_enableFunctionInExtension_functionAlreadyExistsInDefaultExtension() public {
        // Create Extension struct
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "IncrementDecrementMultiply";
        extension.metadata.metadataURI = "ipfs://IncrementDecrementMultiply";
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );

        vm.expectRevert("ExtensionManager: function impl already exists.");
        router.enableFunctionInExtension(extension.metadata.name, fn);
    }

    /*///////////////////////////////////////////////////////////////
                        Scenario tests
    //////////////////////////////////////////////////////////////*/

    /// The following tests are for scenarios that may occur in production use of a base router.

    /// @notice Upgrade a buggy function in a default extension.
    function test_scenario_upgradeBuggyFunction_defaultExtension() public {
        // Disable buggy function in extension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);

        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), address(0));
        assertEq(router.getExtension(defaultExtension1.metadata.name).functions.length, defaultExtension1.functions.length - 1);

        // Create new extension with fixed function
        Extension memory extension;

        // Set metadata
        extension.metadata.name = "MultiplyDivide-Fixed-Multiply";
        extension.metadata.metadataURI = "ipfs://MultiplyDivide-Fixed-Multiply";
        extension.metadata.implementation = address(new MultiplyDivide());   

        // Set functions
        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(
            MultiplyDivide.multiplyNumber.selector,
            "multiplyNumber(uint256)"
        );

        // Call: addExtension
        router.addExtension(extension);

        // Post call checks
        assertEq(router.getImplementationForFunction(MultiplyDivide.multiplyNumber.selector), extension.metadata.implementation);
        assertEq(router.getExtension(defaultExtension1.metadata.name).functions.length, extension.functions.length);

        Extension memory updatedExtension;
        updatedExtension.metadata = defaultExtension1.metadata;
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = defaultExtension1.functions[1];

        _validateExtensionDataOnContract(updatedExtension);
        _validateExtensionDataOnContract(extension);
    }
    
    /// @notice Upgrade a buggy function in a non-default extension.
    function test_scenario_upgradeBuggyFunction() public {
        // Add extension with buggy function
        Extension memory extension;
        
        extension.metadata.name = "IncrementDecrement";
        extension.metadata.metadataURI = "ipfs://IncrementDecrement";
        extension.metadata.implementation = address(new IncrementDecrementGet());

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

        // Call: addExtension
        router.addExtension(extension);

        // Disable buggy function in extension
        router.disableFunctionInExtension(extension.metadata.name, IncrementDecrementGet.getNumber.selector);

        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), address(0));
        assertEq(router.getExtension(extension.metadata.name).functions.length, extension.functions.length - 1);

        // Create new extension with fixed function
        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.name = "IncrementDecrement-getNumber-fixed";
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );

        // Call: addExtension
        router.addExtension(updatedExtension);

        // Post call checks

        assertEq(router.getImplementationForFunction(IncrementDecrementGet.getNumber.selector), updatedExtension.metadata.implementation);
        assertEq(router.getExtension(extension.metadata.name).functions.length, updatedExtension.functions.length);

        _validateExtensionDataOnContract(updatedExtension);
    }
}