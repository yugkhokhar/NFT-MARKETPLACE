//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Price_Should_Be_Greater_Than_Zero();
error Already_Listed(address nftaddress, uint256 tokenid);
error You_are_not_owner();
error Not_Approved();
error Not_Listed(address nftaddress, uint256 tokenid);
error Not_Enough_Provided();
error Not_Enough_To_Withdraw();
error Amount_Transfer_Not_Performed();

contract NftMarketplace is ReentrancyGuard {
    event Item_Listed(
        address indexed nftaddress,
        uint256 indexed tokenid,
        uint256 price,
        address indexed owner
    );
    event Item_Bought_OwnerShip_Transfer(
        address indexed nftaddress,
        address indexed seller,
        uint256 indexed tokenid,
        uint256 price
    );

    event Cancel_Listed(
        address indexed nftaddress,
        uint256 indexed tokenid,
        address indexed seller
    );

    event Updated_Event(address indexed nftaddress, uint256 indexed tokenid);

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) List_Item;
    mapping(address => uint256) seller_earn;

    modifier notListed(address nftaddress, uint256 tokenid) {
        Listing memory listing = List_Item[nftaddress][tokenid];

        if (listing.price > 0) {
            revert Already_Listed(nftaddress, tokenid);
        }
        _;
    }

    modifier isOwner(
        address nftaddress,
        uint256 tokenid,
        address spender
    ) {
        IERC721 nft = IERC721(nftaddress);
        address owner = nft.ownerOf(tokenid);
        if (owner != spender) {
            revert You_are_not_owner();
        }

        _;
    }

    modifier isListed(address nftaddress, uint256 tokenid) {
        Listing memory listing = List_Item[nftaddress][tokenid];
        if (listing.price < 0) {
            revert Not_Listed(nftaddress, tokenid);
        }
        _;
    }

    function Listitem(
        address nftaddress,
        uint256 tokenid,
        uint256 price
    )
        external
        isOwner(nftaddress, tokenid, msg.sender)
        notListed(nftaddress, tokenid)
    {
        if (price < 0) {
            revert Price_Should_Be_Greater_Than_Zero();
        }

        IERC721 nft = IERC721(nftaddress);
        if (nft.getApproved(tokenid) != address(this)) {
            revert Not_Approved();
        }

        List_Item[nftaddress][tokenid] = Listing(price, msg.sender);

        emit Item_Listed(nftaddress, tokenid, price, msg.sender);
    }

    function buyItem(address nftaddress, uint256 tokenid)
        external
        payable
        isListed(nftaddress, tokenid)
        nonReentrant
    {
        //Check the pricing with sender value
        Listing memory listing = List_Item[nftaddress][tokenid];
        if (msg.value < listing.price) {
            revert Not_Enough_Provided();
        }
        //IN THIS THERE IS NO TRANSFER OF BALANCE AND ON BEHALF OF THAT WE HAVE PROVIDED THE FUND TO THAT ACCOUNT
        seller_earn[listing.seller] += msg.value;
        delete (List_Item[nftaddress][tokenid]);
        IERC721(nftaddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenid
        );
        emit Item_Bought_OwnerShip_Transfer(
            nftaddress,
            listing.seller,
            tokenid,
            listing.price
        );
    }

    function CancelList(address nftaddress, uint256 tokenid)
        external
        isOwner(nftaddress, tokenid, msg.sender)
        isListed(nftaddress, tokenid)
    {
        delete (List_Item[nftaddress][tokenid]);
        emit Cancel_Listed(nftaddress, tokenid, msg.sender);
    }

    function UpdateList(
        address nftaddress,
        uint256 tokenid,
        uint256 newPrice
    ) external isOwner(nftaddress, tokenid, msg.sender) {
        List_Item[nftaddress][tokenid].price = newPrice;
        emit Updated_Event(nftaddress, tokenid);
    }

    function WithdrawFromAccount() public {
        uint256 amountfromaccount = seller_earn[msg.sender];
        if (amountfromaccount <= 0) {
            revert Not_Enough_To_Withdraw();
        }
        //Reentrancy Attack Prevention
        seller_earn[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amountfromaccount}(
            ""
        );
        if (!success) {
            revert Amount_Transfer_Not_Performed();
        }
    }

    function getAccount() external view returns (uint256) {
        return seller_earn[msg.sender];
    }

    function getListing(address nftaddress, uint256 tokenid)
        external
        view
        returns (Listing memory)
    {
        return List_Item[nftaddress][tokenid];
    }
}
