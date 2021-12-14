const IconsTokenTest = artifacts.require("IconsTokenTest");
const TeleportCustodyTest = artifacts.require("TeleportCustodyTest");

module.exports = async function (deployer) {
  await deployer.deploy(IconsTokenTest);
  await deployer.deploy(TeleportCustodyTest, IconsTokenTest.address);
};
