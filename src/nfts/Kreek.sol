// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract Kreek is ERC721, ReentrancyGuard, Pausable {
    using Strings for uint256;

    struct Asset {
        uint256 amountIn;
        mapping(address => uint256) amountOut;
        address[] currencies;
        uint256 active;
    }

    event SaleLive(bool live);

    address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string public constant EXTENSION = ".json";

    uint256 public constant DCA_SIZE = 50 ether;
    uint256 public constant MINT_SUPPLY = 1000;
    uint256 public constant MINT_PRICE = 500 ether; // MUST be a multiple of DCA_SIZE
    address public constant MINT_CURRENCY = ETH_MOCK_ADDRESS;

    string public baseUri;
    bool public isSaleLive;
    bool public isTrading;
    uint256 public currentTokenId;
    uint256 public currentEpoch;
    address public kreekHotWallet;
    address public stablecoin;
    address public btc;

    mapping(uint256 => Asset) public balances;
    mapping(uint256 => bool) public hasWithdrawn;
    mapping(address => uint256) public renewalBalance;

    modifier onlyMultisig() {
        require(msg.sender == kreekHotWallet, "Only Kreek Hot Wallet");
        _;
    }

    modifier notBots() {
        require(msg.sender == tx.origin, "No bots");
        _;
    }

    modifier isLive() {
        require(isSaleLive, "Sale has not started");
        _;
    }

    modifier notLive() {
        require(!isSaleLive, "Sale is ongoing");
        _;
    }

    constructor(address _kreekHotWallet) ERC721("Kreek Seasonal Plan 1", "KSP1") {
        Asset storage a = balances[0];
        a.amountIn = MINT_PRICE;
        a.currencies = new address[](0);
        a.active = 0;
        currentEpoch = 0;
        baseUri = "https://kreek.app";
        kreekHotWallet = _kreekHotWallet;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function isEther(address currency) public pure returns (bool) {
        return currency == ETH_MOCK_ADDRESS;
    }

    /**
     * @dev Mints a NFT.
     */
    function mintTo(address recipient) public payable notBots isLive nonReentrant whenNotPaused returns (uint256) {
        require(currentTokenId < MINT_SUPPLY, "No more NFTs left");
        require(currentEpoch == 0, "Please use latest season for minting");

        if (isEther(MINT_CURRENCY)) {
            require(msg.value == MINT_PRICE, "Insufficient Eth supplied");
        } else {
            require(IERC20(MINT_CURRENCY).balanceOf(recipient) >= MINT_PRICE, "Insufficient balance");
            require(IERC20(MINT_CURRENCY).allowance(recipient, address(this)) >= MINT_PRICE, "Please approve");
            IERC20(MINT_CURRENCY).transferFrom(recipient, address(this), MINT_PRICE);
        }

        uint256 newItemId = ++currentTokenId;
        balances[currentEpoch].active++;
        renewalBalance[recipient]++;
        _safeMint(recipient, newItemId);

        return newItemId;
    }

    /**
     * @dev Renewal mint for existing Kreek holders, each `tokenId` can only undergo 1 renewal.
     */
    function renewTo(uint256 tokenId, address recipient)
        public
        payable
        isLive
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        uint256 newItemId = tokenId + 1000 * currentEpoch;
        require(renewalBalance[recipient] > 0, "Recipient did not DCA");
        require(!_exists(newItemId), "Already renewed");

        if (isEther(MINT_CURRENCY)) {
            require(msg.value == MINT_PRICE, "Insufficient Eth supplied");
        } else {
            require(IERC20(MINT_CURRENCY).balanceOf(recipient) >= MINT_PRICE, "Insufficient balance");
            require(IERC20(MINT_CURRENCY).allowance(recipient, address(this)) >= MINT_PRICE, "Please approve");
            IERC20(MINT_CURRENCY).transferFrom(recipient, address(this), MINT_PRICE);
        }

        balances[currentEpoch].active++;
        _safeMint(recipient, newItemId);

        return newItemId;
    }

    /**
     * @dev Advance Kreek to the next epoch, NFT holders may renew their NFT.
     */
    function advanceEpoch() public notLive onlyMultisig {
        require(!isTrading, "Trading is still ongoing");
        require(balances[currentEpoch].amountIn == 0, "Current DCA epoch has yet to end");

        uint256 balance = IERC20(MINT_CURRENCY).balanceOf(address(this));
        if (balance > 0) {
            IERC20(MINT_CURRENCY).approve(kreekHotWallet, balance);
            IERC20(MINT_CURRENCY).transferFrom(address(this), kreekHotWallet, balance);
        }

        currentEpoch++;
        isSaleLive = true;
        Asset storage a = balances[currentEpoch];
        a.amountIn = MINT_PRICE;
        a.currencies = new address[](0);
        a.active = 0;
    }

    /**
     * @dev Withdraws a fix amount of coins to the Kreek Hot Wallet for DCA-ing.
     */
    function trickle() public notLive onlyMultisig {
        require(!isTrading, "Please fill first");

        isTrading = true;
        IERC20(MINT_CURRENCY).transfer(kreekHotWallet, DCA_SIZE * balances[currentEpoch].active);
        balances[currentEpoch].amountIn -= DCA_SIZE;
    }

    /**
     * @dev Allocates tokens (from DCA) to the Kreek NFT from Kreek Hot Wallet.
     */
    function fill(address[] calldata tokenAddresses, uint256[] calldata values) public notLive onlyMultisig {
        require(balances[currentEpoch].active > 0 && isTrading, "There is nothing to fill");

        for (uint256 i = 0; i < values.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 value = values[i];
            IERC20(tokenAddress).transferFrom(kreekHotWallet, address(this), value);
            if (balances[currentEpoch].amountOut[tokenAddress] == 0) {
                balances[currentEpoch].currencies.push(tokenAddress);
            }
            balances[currentEpoch].amountOut[tokenAddress] += value / balances[currentEpoch].active;
        }
        isTrading = false;
    }

    function _withdraw(uint256 tokenId) private {
        uint256 tokenEpoch = tokenId / 1000;
        require(tokenEpoch < currentEpoch || !isTrading, "Withdrawal is unavailable");
        require(msg.sender == ownerOf(tokenId), "Only owner can withdraw");
        require(!hasWithdrawn[tokenId], "Assets already withdrawn");

        hasWithdrawn[tokenId] = true;
        balances[tokenEpoch].active--;
        for (uint256 i = 0; i < balances[tokenEpoch].currencies.length; i++) {
            address currency = balances[tokenEpoch].currencies[i];
            uint256 amount = balances[tokenEpoch].amountOut[currency];
            IERC20(currency).transfer(msg.sender, amount);
        }
        if (balances[tokenEpoch].amountIn > 0) {
            // Did not follow through the DCA
            renewalBalance[msg.sender]--;
            IERC20(MINT_CURRENCY).transfer(msg.sender, balances[tokenEpoch].amountIn);
        }
    }

    /**
     * @dev Returns the underlying tokens to the NFT `tokenId` owner.
     */
    function withdraw(uint256 tokenId) public nonReentrant {
        _withdraw(tokenId);
    }

    /**
     * @dev Returns the underlying tokens to the NFT `tokenIds` owner.
     */
    function withdrawAll(uint256[] calldata tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdraw(tokenIds[i]);
        }
    }

    function togglePublicLive() external onlyMultisig {
        require(!isTrading, "Trading is still ongoing");

        isSaleLive = !isSaleLive;
        emit SaleLive(isSaleLive);
    }

    function setPaused(bool _paused) external onlyMultisig {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns the tokenURI.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), EXTENSION))
            : "";
    }
}
