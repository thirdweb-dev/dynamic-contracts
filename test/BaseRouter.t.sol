// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/presets/BaseRouter.sol";

contract BaseRouterTest is Test {

    BaseRouter internal manager;

    function setUp() public virtual {

        // Deploy BaseRouter
        manager = new BaseRouter();
    }

    /*///////////////////////////////////////////////////////////////
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    // @note: add a new extension
    function test_state_addExtension() public {}

    // @note add a new extension with the receive function.
    function test_state_addExtension_withReceiveFunction() public {}

    // @note: add a new extension with a name that is already used by an existing extension.
    function test_revert_addExtension_nameAlreadyUsed() public {}

    // @note add a new extension with an empty name.
    function test_revert_addExtension_emptyName() public {}

    // @note add a new extension with an empty implementation address.
    function test_revert_addExtension_emptyImplementation() public {}

    // @note add a new extension with fn selector-signature mismatch.
    function test_revert_addExtension_fnSelectorSignatureMismatch() public {}

    // @note add a new extension specifying same function twice.
    function test_revert_addExtension_duplicateFunction() public {}

    // @note add a new extension with empty function signature.
    function test_revert_addExtension_emptyFunctionSignature() public {}

    // @note add a new extension with empty function selector.
    function test_revert_addExtension_emptyFunctionSelector() public {}

    /*///////////////////////////////////////////////////////////////
                            Replacing extensions
    //////////////////////////////////////////////////////////////*/

    // @note: replace an existing extension; new extension has no functions.
    function test_state_replaceExtension_noFunctions() public {}

    // @note: replace an existing extension; new extension has all same functions.
    function test_state_replaceExtension_sameFunctions() public {}

    // @note replace an extension; new extension has all new functions.
    function test_state_replaceExtension_allNewFunctions() public {}

    // @note replace an extension; new extension has some existing functions, some new functions.
    function test_state_replaceExtension_someNewFunctions() public {}

    // @note replace an extension that does not exist.
    function test_revert_replaceExtension_extensionDoesNotExist() public {}

    // @note replace an extension with an empty name.
    function test_revert_replaceExtension_emptyName() public {}

    // @note replace an extension with an empty implementation address.
    function test_revert_replaceExtension_emptyImplementation() public {}

    // @note replace an extension with fn selector-signature mismatch.
    function test_revert_replaceExtension_fnSelectorSignatureMismatch() public {}

    // @note replace an extension specifying same function twice.
    function test_revert_replaceExtension_duplicateFunction() public {}

    // @note replace an extension with empty function signature.
    function test_revert_replaceExtension_emptyFunctionSignature() public {}

    // @note replace an extension with empty function selector.
    function test_revert_replaceExtension_emptyFunctionSelector() public {}

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    // @note: remove an existing extension.
    function test_state_removeExtension() public {}

    // @note remove an extension that does not exist.
    function test_revert_removeExtension_extensionDoesNotExist() public {}

    // @note remove an extension with an empty name.
    function test_revert_removeExtension_emptyName() public {}

    /*///////////////////////////////////////////////////////////////
                        Adding function to extension
    //////////////////////////////////////////////////////////////*/

    // @note: add a new function to an existing extension.
    function test_state_addFunctionToExtension() public {}

    // @note add a receive function to an extension
    function test_state_addFunctionToExtension_receiveFunction() public {}

    // @note add a function to an extension that does not exist.
    function test_revert_addFunctionToExtension_extensionDoesNotExist() public {}

    // @note add a function to an extension which already has the function.
    function test_revert_addFunctionToExtension_functionAlreadyExistsInExtension() public {}

    // @note add a function to an extension, but another extension already has that function.
    function test_revert_addFunctionToExtension_functionAlreadyExistsInAnotherExtension() public {}

    // @note add a function to an extension with an empty function signature.
    function test_revert_addFunctionToExtension_emptyFunctionSignature() public {}

    // @note add a function to an extension with an empty function selector.
    function test_revert_addFunctionToExtension_emptyFunctionSelector() public {}

    // @note add a function to an extension with fn selector-signature mismatch.
    function test_revert_addFunctionToExtension_fnSelectorSignatureMismatch() public {}


    /*///////////////////////////////////////////////////////////////
                    Removing function from extension
    //////////////////////////////////////////////////////////////*/

    // @note remove a function from an existing extension.
    function test_state_removeFunctionFromExtension() public {}

    // @note remove a receive function from an existing extension.
    function test_state_removeFunctionFromExtension_receiveFunction() public {}

    // @note remove a function from an extension that does not exist.
    function test_revert_removeFunctionFromExtension_extensionDoesNotExist() public {}

    // @note remove a function from an extension which does not have the function.
    function test_revert_removeFunctionFromExtension_functionDoesNotExistInExtension() public {}

    // @note remove a function (other than receive function) from an extension with an empty function selector.
    function test_revert_removeFunctionFromExtension_emptyFunctionSelector() public {}

    /*///////////////////////////////////////////////////////////////
                            Scenario tests
    //////////////////////////////////////////////////////////////*/

    // @note: scenario: Update a buggy function by setting a new implementation for it.
    function test_scenario_updateBuggyFunction() public {}

    // @note: scenario: Adding a new extension with a function that clashes with existing extension.
    function test_scenario_addExtensionWithClashingFunction() public {}

    // @note: scenario: Rollback a buggy update to a function.
    function test_scenario_rollbackBuggyFunctionUpdate() public {}

    // @note scenario: Upgrade an extension, but the new extension has a function that clashes with another existing extension.
    function test_scenario_upgradeExtensionWithClashingFunction() public {}

    // @note scenario: Upgrade an extension, update a buggy function in the new extension, update the entire extension again.
    function test_scenario_upgradeIncludesBug() public {}

    // @note scenario: Add an extension, add another extension with clashing fn, resolve by moving clashing function to its own extension.
    function test_scenario_resolveFnClashWithAnotherExtension() public {}
}