const { ethers, network } = require('hardhat')
const { moveBlocks } = require('../utils/moveblocks')
const { developmentChains } = require('../hardhat-helper')
const TOKEN_ID = 0

async function buyItem() {
  const nftMarketplace = await ethers.getContract('NftMarketplace')
  const basicNft = await ethers.getContract('BasicNft')
  const listing = await nftMarketplace.getListing(basicNft.address, TOKEN_ID)
  const price = listing.price.toString()
  const tx = await nftMarketplace.buyItem(basicNft.address, TOKEN_ID, {
    value: price,
  })
  await tx.wait(1)
  console.log('NFT Bought!')
  if (developmentChains.includes(network.name)) {
    await moveBlocks(2, (sleepAmount = 1000))
  }
}

buyItem()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
