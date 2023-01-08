// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "../interfaces/IKreek.sol";

contract Kreek is ERC721, IKreek {
    struct Asset {
        uint256 amountOut;
        uint256 amountIn;
        uint256 active;
    }

    uint256 public constant DCA_SIZE = 50 ether;
    uint256 public constant MINT_PRICE = 500 ether;
    uint256 public currentTokenId;
    uint256 public currentEpoch;
    address public kreekHotWallet;
    address public stablecoin;
    address public btc;
    bool public isTrading;
    Asset[] public fillArray;
    mapping(uint256 => bool) public hasWithdrawn;
    mapping(address => uint256) public renewalBalance;

    modifier onlyMultisig() {
        require(msg.sender == kreekHotWallet);
        _;
    }

    constructor(address _kreekHotWallet, address) ERC721("Kreek Seasonal Plan 1", "KSP1") {
        kreekHotWallet = _kreekHotWallet;
    }

    /**
     * @dev Mints a NFT.
     */
    function mintTo(address recipient) public payable returns (uint256) {
        uint256 newItemId = ++currentTokenId;
        fillArray[currentEpoch].active++;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    /**
     * @dev Returns the tokenURI.
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }

    /**
     * @dev Returns the current renewal epoch.
     */
    function currentRenewalEpoch() external view override returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Returns the amount of tokens owned by NFT `tokenId`.
     */
    function valueOf(uint256 tokenId) external view override returns (Token[] memory) {
        if (hasWithdrawn[tokenId]) {
            return new Token[](0);
        }
        Token[] memory tokens = new Token[](2);
        tokens[0] = Token(stablecoin, fillArray[tokenId / 1000].amountIn);
        tokens[1] = Token(btc, fillArray[tokenId / 1000].amountOut);

        return tokens;
    }

    /**
     * @dev Returns the underlying tokens to the NFT `tokenId` owner.
     */
    function withdraw(uint256 tokenId) external view override returns (Token[] memory) {
        require(!isTrading, "Kreek hot wallet is trading in progress, please wait");

        if (hasWithdrawn[tokenId]) {
            return new Token[](0);
        }
        Token[] memory tokens = new Token[](2);
        tokens[0] = Token(stablecoin, fillArray[tokenId / 1000].amountIn);
        tokens[1] = Token(btc, fillArray[tokenId / 1000].amountOut);

        IERC20(stablecoin).transferFrom(address(this), ownerOf(tokenId), tokens[0].value);
        IERC20(btc).transferFrom(address(this), ownerOf(tokenId), tokens[0].value);

        hasWithdrawn[tokenId] = true;

        return tokens;
    }

    /**
     * @dev Returns the underlying tokens to the NFT `tokenIds` owner.
     */
    function withdrawAll(uint256[] calldata tokenIds) external view override returns (Token[] memory) {
        Token[] memory tokens = new Token[](2);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            Token[] memory temp = withdraw(tokenIds[i]);
            if (i == 0) {
                tokens = temp;
            } else {
                tokens[0].value += temp[0].value;
                tokens[1].value += temp[1].value;
            }
        }
        return tokens;
    }

    /**
     * @dev Renewal mint for existing Kreek holders, each `tokenId` can only undergo 1 renewal.
     */
    function renewalMint(uint256 tokenId) external override {
        require(renewalBalance[msg.sender] > 0, "You shall not pass, you did not DCA");

        mintTo(ownerOf(msg.sender));
    }

    /**
     * @dev Renew Kreek for the next epoch.
     */
    function renew() external override {
        currentEpoch++;
        fillArray.push(Asset(MINT_PRICE, 0, 0));
    }

    /**
     * @dev Withdraws a fix amount of stablecoins to the Kreek Hot Wallet for DCA-ing.
     */
    function trickle() external override {
        IERC20(stablecoin).approve(kreekHotWallet, DCA_SIZE * fillArray[currentEpoch].active);
        IERC20(stablecoin).transferFrom(address(this), kreekHotWallet, DCA_SIZE * fillArray[currentEpoch].active);
        isTrading = true;
    }

    /**
     * @dev Allocates tokens (from DCA) to the Kreek NFT from Kreek Hot Wallet or any generous donor.
     */
    function fill(address tokenAddress, uint256 value) external override {
        IERC20(btc).transferFrom(kreekHotWallet, address(this), DCA_SIZE * fillArray[currentEpoch].active);
        fillArray.amountOut += value;

        isTrading = false;
    }
}
