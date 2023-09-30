const rrps = artifacts.require("rrps");

module.exports = function(deployer) {
    deployer.deploy(rrps);
}
