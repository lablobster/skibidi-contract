// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPegasysV3Factory} from "@pollum-io/v3-core/contracts/interfaces/IPegasysV3Factory.sol";
import {IPegasysV3Pool} from "@pollum-io/v3-core/contracts/interfaces/IPegasysV3Pool.sol";
import {INonfungiblePositionManager} from "@pollum-io/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "@pollum-io/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/*
   ▄████████    ▄█   ▄█▄  ▄█  ▀█████████▄   ▄█  ████████▄   ▄█  
  ███    ███   ███ ▄███▀ ███    ███    ███ ███  ███   ▀███ ███  
  ███    █▀    ███▐██▀   ███▌   ███    ███ ███▌ ███    ███ ███▌ 
  ███         ▄█████▀    ███▌  ▄███▄▄▄██▀  ███▌ ███    ███ ███▌ 
▀███████████ ▀▀█████▄    ███▌ ▀▀███▀▀▀██▄  ███▌ ███    ███ ███▌ 
         ███   ███▐██▄   ███    ███    ██▄ ███  ███    ███ ███  
   ▄█    ███   ███ ▀███▄ ███    ███    ███ ███  ███   ▄███ ███  
 ▄████████▀    ███   ▀█▀ █▀   ▄█████████▀  █▀   ████████▀  █▀   
               ▀                                                
    ███      ▄██████▄   ▄█   ▄█          ▄████████     ███     
▀█████████▄ ███    ███ ███  ███         ███    ███ ▀█████████▄ 
   ▀███▀▀██ ███    ███ ███▌ ███         ███    █▀     ▀███▀▀██ 
    ███   ▀ ███    ███ ███▌ ███        ▄███▄▄▄         ███   ▀ 
    ███     ███    ███ ███▌ ███       ▀▀███▀▀▀         ███     
    ███     ███    ███ ███  ███         ███    █▄      ███     
    ███     ███    ███ ███  ███▌    ▄   ███    ███     ███     
   ▄████▀    ▀██████▀  █▀   █████▄▄██   ██████████    ▄████▀                                                             
*/
/// @title Skibidi Token Contract
/// @notice This contract implements tokenomics and functionalities for the SKBD token, including LP fee claiming and burning mechanism.
contract Skibidi is ERC20 {
    using Address for address;

    // Address of the Pegasys (PSYS) token.
    address private constant PSYS = 0x48023b16c3e81AA7F6eFFbdEB35Bb83f4f31a8fd;
    // Address used for burning tokens.
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    // The Pegasys V3 Factory contract address for creating and managing pools.
    IPegasysV3Factory private constant FACTORY =
        IPegasysV3Factory(0xeAa20BEA58979386A7d37BAeb4C1522892c74640);
    // The Non-fungible Position Manager for managing liquidity positions.
    INonfungiblePositionManager private constant POSITION_MANAGER =
        INonfungiblePositionManager(0x4dB158Eec5c5d63F9A09535882b835f36d3fd012);
    // The Swap Router for executing token swaps.
    ISwapRouter private constant SWAP_ROUTER =
        ISwapRouter(0xd93c60A8E0F53361524698Cce1BBb65E080b8976);

    /// @notice The Pegasys V3 Pool associated with this token.
    IPegasysV3Pool public pool;

    /// @dev Initializes the contract, mints the total supply to the deployer, and creates a pool with PSYS.
    constructor() ERC20("SKIBIDI TOILET", "SKBD") {
        _mint(_msgSender(), 696969696969696969e18);
        pool = IPegasysV3Pool(FACTORY.createPool(address(this), PSYS, 10000));
    }

    /// @notice Claims LP fees for the provided token IDs and burns the collected WSYS tokens by swapping them for SKBD and then transferring to the dead address.
    /// @param tokenIds An array of token IDs for which to claim LP fees.
    function claimLpFeeAndBurn(uint256[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            POSITION_MANAGER.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenIds[i],
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
        }

        uint256 psysBalance = IERC20(PSYS).balanceOf(address(this));
        IERC20(PSYS).approve(address(SWAP_ROUTER), psysBalance);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: PSYS,
                tokenOut: address(this),
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: psysBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        SWAP_ROUTER.exactInputSingle(params);
        transfer(DEAD, balanceOf(address(this)));
    }

    /// @dev Overrides the _transfer function to apply a 4.20% fee for transactions, transferring the fee to the dead address.
    /// @param sender The address sending the tokens.
    /// @param recipient The address receiving the tokens.
    /// @param amount The amount of tokens to be transferred.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 feePercentage = 420; // Represents a 4.20% fee
        uint256 feeAmount = 0;
        uint256 amountAfterFee = amount;

        // Applies a fee only if recipient is an EOA
        if (!recipient.isContract()) {
            feeAmount = (amount * feePercentage) / 10000;
            amountAfterFee = amount - feeAmount;

            // Transfers the fee to the dead address
            super._transfer(sender, DEAD, feeAmount);
        }

        // Transfers the remaining amount after deducting the fee
        super._transfer(sender, recipient, amountAfterFee);
    }
}
