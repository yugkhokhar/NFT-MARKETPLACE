const { frontEndContractsFile } = require('../hardhat-helper')
require('dotenv').config()
const fs = require('fs')
const { network } = require('hardhat')

module.exports = async () => {
  if (process.env.UPDATE_IN_FRONTEND) {
    console.log('Writing to front end...')
    await updateContractAddresses()
    console.log('Front end written!')
  }
}

async function updateContractAddresses() {
  const chainId = network.config.chainId.toString()
  const nftMarketplace = await ethers.getContract('NftMarketplace')
  const contractAddresses = JSON.parse(
    fs.readFileSync(frontEndContractsFile, 'utf8'),
  )
  if (chainId in contractAddresses) {
    if (
      !contractAddresses[chainId]['NftMarketplace'].includes(
        nftMarketplace.address,
      )
    ) {
      contractAddresses[chainId]['NftMarketplace'].push(nftMarketplace.address)
    }
  } else {
    contractAddresses[chainId] = { NftMarketplace: [nftMarketplace.address] }
  }
  fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ['all', 'frontend']
