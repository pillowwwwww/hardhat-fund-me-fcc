//不需要main了
const { network } = require("hardhat");
require("dotenv").config();

//1.导入网络配置
const {
    networkConfig,
    developmentChains,
} = require("../helper-hardhat-config"); //提取networkConfig，从helper-hardhat-config.js文件中

//方法1： hre是hardhat运行环境
// async function deployfuc(hre) {
//     console.log("============");
// }
// module.exports.default = deployfuc;

//方法2:
//匿名函数module.exports = async() => {}
// module.exports = async (hre) => {
//     const { getNamedAccounts, deployments }=hre
// };

//方法三：
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts(); //在hardhat.config.js中设置namedAccounts
    const chainId = network.config.chainId;

    const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
    log("----------------------------------------------------");
    log("Deploying FundMe and waiting for confirmations...");
    //部署
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: [ethUsdPriceFeedAddress], //构造函数的参数，priceFeedAddress
        //我们不想使用硬编码，希望实现if chainId is X use address Y, if chinaId is Z, use address C
        //所以使用aave，部署到多个链上并使用多个不同的地址helper-hardhat-config.js
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    log(`FundMe deployed at ${fundMe.address}`);
};

module.exports.tags = ["all", "fundme"];
