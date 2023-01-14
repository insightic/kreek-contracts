// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev Interface of the Kreek Seasonal Plan 1.
 */
interface IKreek {
    /**
     * @dev Token struct containing token `address` and token `amount`
     */
    struct Token {
        address token;
        uint256 value;
    }

    /**
     * @dev Emitted when `value` tokens (Stablecoins) are moved from Kreek NFT (`from`) to
     * Kreek Hot Wallet (`to`).
     *
     * Note that `value` may be zero.
     */
    event Trickler(address indexed from, address indexed to, address tokenAddress, uint256 value);

    /**
     * @dev Emitted when `value` tokens (crypto) are moved from Kreek Hot Wallet (`from`) to
     * Kreek NFT (`to`).
     */
    event Filling(address indexed from, address indexed to, address tokenAddress, uint256 value);

    /**
     * @dev Returns the current renewal epoch.
     */
    function currentRenewalEpoch() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by NFT `tokenId`.
     */
    function valueOf(uint256 tokenId) external view returns (Token[] memory);

    /**
     * @dev Returns the underlying tokens to the NFT `tokenId` owner.
     */
    function withdraw(uint256 tokenId) external view returns (Token[] memory);

    /**
     * @dev Returns the underlying tokens to the NFT `tokenIds` owner.
     */
    function withdrawAll(uint256[] calldata tokenIds) external view returns (Token[] memory);

    /**
     * @dev Renewal mint for existing Kreek holders, each `tokenId` can only undergo 1 renewal.
     */
    function renewTo(uint256 tokenId) external;

    /**
     * @dev Advance Kreek to the next epoch.
     */
    function advanceEpoch() external;

    /**
     * @dev Withdraws a fix amount of stablecoins to the Kreek Hot Wallet for DCA-ing.
     */
    function trickle() external;

    /**
     * @dev Allocates tokens (from DCA) to the Kreek NFT from Kreek Hot Wallet or any generous donor.
     */
    function fill(address tokenAddress, uint256 value) external;
}
