// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library DataTypes {
    enum StudentMode {
        INVEST,
        SAVE_ONLY
    }

    enum StrategyOption {
        CONSERVATIVE,
        MODERATE,
        AGGRESSIVE
    }

    struct TargetPriceParams {
        uint256 sellBasisPoints;
        uint256 priceIncreaseBasisPoints;
    }

    struct StrategyParams {
        TargetPriceParams targetPrice1;
        TargetPriceParams targetPrice2;
        TargetPriceParams targetPrice3;
        // Stop loss
        uint256 priceDecreaseBasisPoints;
    }
}
