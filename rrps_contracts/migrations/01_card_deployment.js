const Card = artifacts.require("Card");
const Star = artifacts.require("Star");

module.exports = function(deployer) {
    deployer.deploy(Card);
    deployer.deploy(Star);
}