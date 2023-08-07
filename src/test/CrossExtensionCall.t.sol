// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "@std/Test.sol";
import "src/presets/BaseRouter.sol";

/**
 *  Related: https://github.com/thirdweb-dev/dynamic-contracts/issues/6
 *
 *  This test compares the gas cost of cross-contract calls (`Contract A` making an external call to `Contract B`) and
 *  cross-extension calls (`Contract X` has `Contract A` and `Contract B` as extensions; extension `Contract A` calls external
 *  function on `Contract B`).
 */

contract CrossExtensionCallTest is Test {

    address public actor = address(0x123);

    address public dummy_crossExtensionCall;
    address public dummy_crossContractCall;

    function setUp() public {

        vm.label(actor, "Actor");

        // Setup Dummy_CrossExtensionContractCall
        IExtension.Extension memory numberExtension;
        IExtension.Extension memory ownableExtension;

        numberExtension.metadata = IExtension.ExtensionMetadata({
            name: "Number",
            metadataURI: "ipfs://Number",
            implementation: address(new NumberOne())
        });
        ownableExtension.metadata = IExtension.ExtensionMetadata({
            name: "Ownable",
            metadataURI: "ipfs://Ownable",
            implementation: address(new Ownable())
        });

        numberExtension.functions = new IExtension.ExtensionFunction[](1);
        ownableExtension.functions = new IExtension.ExtensionFunction[](2);

        numberExtension.functions[0] = IExtension.ExtensionFunction(
            NumberOne.setNumber.selector,
            "setNumber(uint256)"
        );
        ownableExtension.functions[0] = IExtension.ExtensionFunction(
            Ownable.owner.selector,
            "owner()"
        );
        ownableExtension.functions[1] = IExtension.ExtensionFunction(
            Ownable.setOwner.selector,
            "setOwner(address)"
        );

        vm.startPrank(actor);

        dummy_crossExtensionCall = address(new Dummy_CrossExtensionContractCall(new IExtension.Extension[](0)));
        Dummy_CrossExtensionContractCall(payable(dummy_crossExtensionCall)).addExtension(numberExtension);
        Dummy_CrossExtensionContractCall(payable(dummy_crossExtensionCall)).addExtension(ownableExtension);
        Dummy_CrossExtensionContractCall(payable(dummy_crossExtensionCall)).initialize();

        // Setup Dummy_CrossContractCall
        address ownable = address(new Ownable());
        dummy_crossContractCall = address(new Dummy_CrossContractCall(ownable));

        vm.stopPrank();
    }

    function test_benchmark_crossExtensionCall() public {
        vm.prank(actor);
        NumberTwo(dummy_crossExtensionCall).setNumber(1);
    }

    function test_benchmark_crossContractCall() public {
        vm.prank(actor);
        Dummy_CrossContractCall(dummy_crossContractCall).setNumber(1);
    }
}


library OwnableStorage {
    bytes32 public constant OWNABLE_STORAGE_POSITION = keccak256("ownable.storage");

    struct Data {
        /// @dev Owner of the contract (purpose: OpenSea compatibility)
        address _owner;
    }

    function ownableStorage() internal pure returns (Data storage ownableData) {
        bytes32 position = OWNABLE_STORAGE_POSITION;
        assembly {
            ownableData.slot := position
        }
    }
}

contract Ownable {

    function owner() public view returns (address) {
        return OwnableStorage.ownableStorage()._owner;
    }

    function setOwner(address _newOwner) external {
        OwnableStorage.ownableStorage()._owner = _newOwner;
    }
    function _setupOwner(address _newOwner) internal {
        OwnableStorage.ownableStorage()._owner = _newOwner;
    }
}

library NumberStorage {
    bytes32 public constant NUMBER_STORAGE_POSITION = keccak256("number.storage");

    struct Data {
        uint256 number;
    }

    function numberStorage() internal pure returns (Data storage numberData) {
        bytes32 position = NUMBER_STORAGE_POSITION;
        assembly {
            numberData.slot := position
        }
    }
}

contract NumberOne {
    function setNumber(uint256 _num) external {
        address owner = Ownable(address(this)).owner();
        require(owner == msg.sender, "Number: caller is not the owner");
        NumberStorage.numberStorage().number = _num;
    }
}

contract NumberTwo {

    address public immutable ownable;

    constructor(address _ownable) {
        ownable = _ownable;
    }

    function setNumber(uint256 _num) external {
        address owner = Ownable(ownable).owner();
        require(owner == msg.sender, "Number: caller is not the owner");
        NumberStorage.numberStorage().number = _num;
    }
}

contract Dummy_CrossContractCall is NumberTwo {
    constructor(address _ownable) NumberTwo(_ownable) {
        Ownable(_ownable).setOwner(msg.sender);
    }
}

contract Dummy_CrossExtensionContractCall is BaseRouter {
    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {}

    function initialize() public {
        Ownable(address(this)).setOwner(msg.sender);
    }

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension(Extension memory) internal pure override returns (bool) {
        return true;
    }
}