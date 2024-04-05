// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Simple mock NFT with no restrictions on minting. Suitable for testing.
 */
contract MockNFT is ERC721 {
    error MockNFT__ZeroAddress();
    error MockNFT__MaxSupply();

    uint256 _tokenCounter;
    uint256 _maxSupply;

    constructor(uint256 maxSupply_) ERC721("MockNFT", "MKDNFT") {
        _maxSupply = maxSupply_;
    }

    function mint(address account) external {
        if (account == address(0)) revert MockNFT__ZeroAddress();
        if (_tokenCounter == _maxSupply) revert MockNFT__MaxSupply();

        // id will start at 1
        _tokenCounter++;

        uint256 id = _tokenCounter;

        _mint(account, id);
    }
}
