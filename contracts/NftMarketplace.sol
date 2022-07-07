// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__PriceMustBeAoveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();

contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );

    // NFT Contract address -> NFT Token ID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    /////////////////////
    //    Modifier     //
    /////////////////////

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    // only owner of the nft can list item
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAoveZero();
        }
        // option-1. Send the NFT to the contract. Transfer -> Contract "hold" the NFT
        // option-2. Owners can still hold their NFT, and give the marketplace approval to sell the NFT for them.
        // => going for option-2.
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }
}

/*
    1. `listItem`: List NFTs on the marketplace
    2. `buyItem`: Buy the NFTs
    3. `cancelItem`: Cancel a listing
    4. `updateListing`: Update Price
    5. `withdrawProceeds`: Withdraw payment for my bought NFTs
*/
