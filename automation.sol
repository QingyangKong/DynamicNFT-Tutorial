// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Dogs.sol";

contract Counter is AutomationCompatibleInterface {

    Dogs public dogs;

    constructor(address dogsAddr) {
        dogs = Dogs(dogsAddr);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (dogs.currentTmp() != dogs.latestTmp());
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        dogs.updateMetadata();
    }
}
