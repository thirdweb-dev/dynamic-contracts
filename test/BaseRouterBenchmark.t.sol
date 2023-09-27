// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

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

contract BaseRouterBenchmarkTest is Test, IExtension {

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
                        Deploy / Initialze BaseRouter
    //////////////////////////////////////////////////////////////*/

    /// @notice Check with a single extension with 10 functions
    function test_benchmark_deployBaseRouter() external {
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Check with multiple extensions extension with ~50 functions in total
    function test_benchmark_deployBaseRouter_multipleExtensions() external {
        Extension[] memory defaultExtensionsNew = new Extension[](3);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension4;
        defaultExtensionsNew[2] = defaultExtension5;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
    }

    /// @notice Check with a single extension with 10 functions
    function test_benchmark_initializeBaseRouter_singleExtension() external {
        // vm.pauseGasMetering();
        Extension[] memory defaultExtensionsNew = new Extension[](1);
        defaultExtensionsNew[0] = defaultExtension3;
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
        // vm.resumeGasMetering();

        uint256 gasBefore = gasleft();
        routerNew.initialize();
        uint256 gasAfter = gasleft();
        console.log(gasBefore - gasAfter);
    }

    /// @notice Check with multiple extensions extension with 50-100 functions in total
    function test_benchmark_initializeBaseRouter_multipleExtensions() external {
        // vm.pauseGasMetering();
        Extension[] memory defaultExtensionsNew = new Extension[](3);
        defaultExtensionsNew[0] = defaultExtension3;
        defaultExtensionsNew[1] = defaultExtension4;
        defaultExtensionsNew[2] = defaultExtension5;
        
        CustomRouter routerNew = new CustomRouter(defaultExtensionsNew);
        // vm.resumeGasMetering();

        uint256 gasBefore = gasleft();
        routerNew.initialize();
        uint256 gasAfter = gasleft();
        console.log(gasBefore - gasAfter);
    }
    

    /*///////////////////////////////////////////////////////////////
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Add an new extension.
    function test_benchmark_addExtension() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();

        // Call: addExtension
        router.addExtension(extension);
    }

    /*///////////////////////////////////////////////////////////////
                            Replace extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Replace a default extension with a new one.
    function test_benchmark_replaceExtension_defaultExtension() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();

        // Call: addExtension
        router.replaceExtension(updatedExtension);
    }

    

    /// @notice Replace a non-default extension with a new one.
    function test_benchmark_replaceExtension() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();

        // Call: addExtension
        router.replaceExtension(updatedExtension);
    }

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    /// @notice Remove a default extension.
    function test_benchmark_removeExtension_defautlExtension() public {
        // Call: removeExtension

        router.removeExtension(defaultExtension1.metadata.name);
    }

    /// @notice Remove a non-default extension.
    function test_benchmark_removeExtension() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();

        // Call: replaceExtension
        router.replaceExtension(updatedExtension);
    }

    /*///////////////////////////////////////////////////////////////
                    Disabling function in extension
    //////////////////////////////////////////////////////////////*/

    /// @notice Disable a function in a default extension.
    function test_benchmark_disableFunctionInExtension_defaultExtension() public {
        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);
    }

    /// @notice Disable a function in a non-default extension.
    function test_benchmark_disableFunctionInExtension() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();

        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(extension.metadata.name, IncrementDecrementGet.incrementNumber.selector);
    }

    /*///////////////////////////////////////////////////////////////
                    Enable function in extension
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable a function in a default extension.
    function test_benchmark_enableFunctionInExtension_defaultExtension() public {
        vm.pauseGasMetering();
        // Call: disableFunctionInExtension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);
        vm.resumeGasMetering();

        // Call: enableFunctionInExtension
        router.enableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0]);
    }

    /// @notice Enable a function in a non-default extension.
    function test_benchmark_enableFunctionInExtension() public {
        vm.pauseGasMetering();
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

        // Call: enableFunctionInExtension
        ExtensionFunction memory fn = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        vm.resumeGasMetering();

        router.enableFunctionInExtension(extension.metadata.name, fn);
    }

    /*///////////////////////////////////////////////////////////////
                        Scenario tests
    //////////////////////////////////////////////////////////////*/

    /// The following tests are for scenarios that may occur in production use of a base router.

    /// @notice Upgrade a buggy function in a default extension.
    function test_benchmark_upgradeBuggyFunction_defaultExtension() public {
        vm.pauseGasMetering();
        // Disable buggy function in extension
        router.disableFunctionInExtension(defaultExtension1.metadata.name, defaultExtension1.functions[0].functionSelector);

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
        vm.resumeGasMetering();

        // Call: addExtension
        router.addExtension(extension);
    }
    
    /// @notice Upgrade a buggy function in a non-default extension.
    function test_benchmark_upgradeBuggyFunction() public {
        vm.pauseGasMetering();
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

        // Create new extension with fixed function
        Extension memory updatedExtension;
        updatedExtension.metadata = extension.metadata;
        updatedExtension.metadata.name = "IncrementDecrement-getNumber-fixed";
        updatedExtension.functions = new ExtensionFunction[](1);
        updatedExtension.functions[0] = ExtensionFunction(
            IncrementDecrementGet.getNumber.selector,
            "getNumber()"
        );
        vm.resumeGasMetering();

        // Call: addExtension
        router.addExtension(updatedExtension);
    }
}