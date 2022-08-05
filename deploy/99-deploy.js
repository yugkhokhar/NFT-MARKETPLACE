const { network, ethers } = require('hardhat')
const fs = require('fs')
const pathofFrontend =
  '../../next-js-MarketPlace-moralis/constants/contract.json'

module.exports = async () => {
  if (process.env.UPDATE_FRONT_END) {
    await updateFrontEnd()
  }
}

const updateFrontEnd = async () => {
  const contract = await ethers.getContract('NftMarketplace')
  const chainid = network.config.chainId.toString()
  const contractaddressjson = JSON.parse(
    fs.readFileSync(pathofFrontend, 'utf8'),
  )

  if (chainid in contractaddressjson) {
    if (
      !contractaddressjson[chainid]['NftMarketplace'].includes(contract.address)
    ) {
      contractaddressjson[chainid]['NftMarketplace'].push(contract.address)
    }
  } else {
    contractaddressjson[chainid] = { "NftMarketplace": [contract.address] }
  }
  fs.write(pathofFrontend, JSON.stringify(contractaddressjson))
}

module.exports.tags = ['all', 'frontend']
