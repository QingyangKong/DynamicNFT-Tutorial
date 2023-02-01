// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// city code 供参考城市代码
// http://www.gov.cn/test/2011-08/22/content_1930111.htm
// - 北京：110000
// - 深圳: 440300
// - 三亚：460200
// - 西双版纳：532800

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./ProfileNft.sol";

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;
    MyToken private mytoken;
    string public cityCode;

    event fulfillTemp(bytes32 requestId, int temp);

    constructor(address mytokenAddr) ConfirmedOwner(msg.sender) {
        /**
         * 设置 LINK token 地址
         * 设置 Chainlink 节点的 operator 合约地址
         * 设置 Chainlink 节点中的 jobId
         * 参考：https://docs.chain.link/any-api/testnet-oracles 中的测试网设置
         * 如果自己运行节点请参考教程：https://www.bilibili.com/video/BV1ed4y1N7Uv
         * **/
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x102Cc8CC5c8603D6142D357Fa9035Eb4ab90C9B6);
        jobId = "89133dfa090442748b98bf9dce72a673";
        
        // Chainlink 节点的服务费，设置为 0.1 LINK（会随着网络和 job 的变化而发生变化）
        // 0.1 * 10**18 (Varies by network and job)
        fee = (1 * LINK_DIVISIBILITY) / 10; 
        mytoken = MyToken(mytokenAddr);
    }

    /**
     * city code 供参考城市代码
     * http://www.gov.cn/test/2011-08/22/content_1930111.htm
     *  - 北京：110000
     *  - 深圳: 440300
     *  - 三亚：460200
     *  - 西双版纳：532800
     * **/
    function setCityCode(string memory _cityCode) external onlyOwner {
        cityCode = _cityCode;
    }

    function requestTemparetureData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Please add city code in the line of code
        // 可以在这里找到气温服务的 Api key： https://lbs.amap.com/api/webservice/guide/api/weatherinfo
        string memory api = string(abi.encodePacked(
            "https://restapi.amap.com/v3/weather/weatherInfo?city=", 
            cityCode, 
            "&key=<add your key>"));

        req.add("get", api);

        req.add("path", "lives,0,temperature"); 

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10 ** 18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        int256 _temperature
    ) public recordChainlinkFulfillment(_requestId) {
        mytoken.updateLastestTemperature(_temperature);
        emit fulfillTemp(_requestId, _temperature);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}