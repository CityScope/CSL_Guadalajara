const Migrations = artifacts.require("Migrations");
const Vaccine = artifacts.require("Vaccine");
const Reception = artifacts.require("Reception");
const Application = artifacts.require("Application");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Vaccine);
  deployer.deploy(Reception);
  deployer.deploy(Application);
};
