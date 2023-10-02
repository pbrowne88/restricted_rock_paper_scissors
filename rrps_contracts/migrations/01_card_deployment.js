const rrps = artifacts.require("RRPS");

module.exports = function(deployer) {
    deployer.deploy(rrps);
}
