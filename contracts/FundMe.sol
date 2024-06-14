// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//通过自定义错误，而不是返回一串字符串"You need to spend more ETH!"，可以减少gas消耗 if () revert NotOwner;
error FundMe__NotOwner();

/// @title  A countract for crowd funding
/// @author Chang Liu
/// @notice demo a sample funding contract

contract FundMe {
    using PriceConverter for uint256; //作为一个library附着于uint256上

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    //只设置一次的变量：使用constant和immutable，减少gas的使用。因为它们存在了合约的字节码中，而不是存到存储槽中
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    //构造器：在部署合约后立刻调用
    //我们希望withdraw函数只有合约的拥有者才能调用
    AggregatorV3Interface private priceFeed;
    constructor(address priceFeedAddress){
        i_owner = msg.sender; //部署这个合约的人
        //第七节课，mocking
        //这样priceFeed是可变的也是模块化的，具体的值取决于我们在哪个链上
        priceFeed=AggregatorV3Interface(priceFeedAddress);
    }
    
    //modifier：可以直接在函数中声明的关键词，修饰该函数的某些功能
    modifier onlyOwner {
        // require(msg.sender == owner， "Sender is not owner");
        if (msg.sender != i_owner) {revert FundMe__NotOwner();}
        _;//运行原函数withdraw()剩下的代码
    }
    function fund() public payable {
        //语法：msg.value.getConversionRate()默认msg.value为第一个参数
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value; //同一个人可能进行多次pay，进行累加
        funders.push(msg.sender);
    }
    /*
    function getVersion() public view returns (uint256){
        // ETH/USD price feed address of Sepolia Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }
   */ 

    
    //在运行withdraw之前，先运行modifier检查是否为owner
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //置空一个数组 
        funders = new address[](0);
        //发送以太币的三种方法：transfer/send/call
        // // transfer 转移资金，出错直接回滚
        // payable(msg.sender).transfer(address(this).balance);
        // send 出错不会报错，返回一个运行是否成功的bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call 返回一个运行是否成功的bool和一个*，
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    


    
//如果有人向这份智能合约发送了ETH，但不是通过fund方法发送的，我们无法追踪发送者信息，怎么办？
// receive(){ 一个合约最多有一个receive函数}

    // Explainer from: https://solidity-by-example.org/fallback/
    // ETH被发送到合约上
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    //如果收到ETH但没有与该交易相关的数据，这个receive函数就会被触发
    receive() external payable {
        fund();
    }

}






// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

