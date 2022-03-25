// SPDX-License-Identifier: GPL-3.0
// Solved loop hole 
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol (THESE FUNCTION YOU CAN USE AT BELOW WHEN YOU CONTRACT "IS ERC721Enumerable"

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 3; //each WL can max mint 3
  bool public paused = false;
  bool public revealed = false;
  //mapping(address => bool) public whitelisted; //substitute by below 2 if follow hashlip
  mapping(address => uint256) public addressMintedBalance; //new 用來record address mint完transfer走再mint, 用map記低他mint了多少隻
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses; //the list of WL.
  
  
  constructor(
    string memory _name, //一開始整SC要入的資料
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI); //function set 公開uri
    setNotRevealedURI(_initNotRevealedUri); //function set埋未公開uri
    mint(20); //founder mint = founder create this contract so he is msg.sender, no need mention.
    // (or just use Mint or try _mint (have error), _safeMint(msg.sender, 20); //(Founder team mint for treasury when contract is created)
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused);
    uint256 supply = totalSupply(); //totalSupply() is inheritance from ERC721Enumerable (so you will not see it define here)
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        //if(whitelisted[msg.sender] != true) {
        if(onlyWhitelisted == true) {  //this part means if WLonly is true then only WL can mint.
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            
        }
        require(msg.value >= cost * _mintAmount);
    }
    // 以上都附合就可mint (用loopMint)
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i); // this function comes from ERC721Enumerable (didnt show) 入面再call ERC721.sol framework.
    }
  }

  // function to check if address is WLed, create a array of address above, use FOR LOOP to scan thru it.
  function isWhitelisted(address _user) public view returns (bool) {
      // for loop to loop thru if the msg.sender is WL : 
      for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
          if(whitelistedAddresses[i] == _user) {
              return true;
          }
      }
      return false;
  }
  
  // show a list of token#id that an address have
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner); //balanceOf is ERC721.sol function (used in ERC721Enumerable)
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) //return the tokenURI : eg. google.com/4.json
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner (Can edit param)
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
   
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state; //only WL address can now buy
  }
 
  
 //function whitelistUser(address _user) public onlyOwner {
    //whitelisted[_user] = true;
  //}
  
  // youtube teach this instead : (WHY DELETE whitelistedAddresses? will it delete what is previously store? OR 要一次過ADD IN? Once WL is closed, 一個function一次過加曬 (also need check if PC can support)
  // *TEST can 分開加, 會否真係會delete之前, 點樣用append instead.
  function whitelistUsers(address[] calldata _users) public onlyOwner {
     delete whitelistedAddresses;
     whitelistedAddresses = _users;
  }
 
 // why not do this?
  //function removeWhitelistUser(address _user) public onlyOwner {
    //whitelisted[_user] = false;
  //}

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
