// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PokemonsNFTs is ERC721, ERC721URIStorage, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    bytes32 private jobId;
    uint256 private fee;


    event CreatePokemon(
        bytes32 indexed requestId,
        uint256 idToken,
        uint256 idPokemon,
        string  uri
    );

    constructor() ERC721("MyToken", "MTK") {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x38aC3a3d17e38b7B4fFc07c28Ad6f3aECeD5A4d8);
        jobId = "a8e42bfe61b74362a5c8fb4676cbb621";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function safeMint()
        public
    {
        requestMultipleParameters();
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function requestMultipleParameters() private {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillMultipleParameters.selector
        );

        req.add(
            "toAddress",
            Strings.toHexString(msg.sender)
        );
        
        sendChainlinkRequest(req, fee); 
    }

    function fulfillMultipleParameters(
        bytes32 requestId,
        address to,
        uint256 id,
        string memory uri
    ) public recordChainlinkFulfillment(requestId) {

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit CreatePokemon(requestId, tokenId, id, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
       bytes memory tempEmptyStringTest = bytes(source);
       if (tempEmptyStringTest.length == 0) {
           return 0x0;
       }
   
       assembly {
           result := mload(add(source, 32))
       }
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
