# Upgradeable Contracts and Patterns

We know that smart contracts on Ethereum are not upgradeable, as the code is immutable and cannot be changed once it is deployed. But writing perfect code the first time around is hard, and as humans we are all prone to making mistakes. Sometimes even contracts which have been audited turn out to have bugs that cost them millions.

In this level, we will learn about some design patterns that can be used in Solidity to write upgradeable smart contracts.

## How does it work?

To upgrade our contracts we use something called the `Proxy Pattern`. The word `Proxy` might sound very familiar to you because it is not a web3-native word.

![](https://i.imgur.com/llJGnTF.png)

Essentially how this pattern works is that a contract is split into two contracts - `Proxy Contract` and the `Implementation` contract.

The `Proxy Contract` is responsible for managing the state of the contract which involves persistent storage whereas `Implementation Contract` is responsible for executing the logic and doesn't store any persistent state. User calls the `Proxy Contract` which further does a `delegatecall` to the `Implementation Contract` so that it can implement the logic. Remember we studied `delegatecall` in one of our previous levels 👀

![](https://i.imgur.com/NpGQqsL.png)

This pattern becomes interesting when `Implementation Contract` can be replaced which means the logic which is executed can be replaced by another version of the `Implementation Contract` without affecting the state of the contract which is stored in the proxy.

There are mainly three ways in which we can replace/upgrade the `Implementation Contract`:

1. Diamond Implementation
2. Transparent Implementation
3. UUPS Implementation

We will however only focus on Transparent and UUPS because they are the most commonly used ones.

To upgrade the `Implementation Contract` you will have to use some method like `upgradeTo(address)` which will essentially change the address of the `Implementation Contract` from the old one to the new one.

But the important part lies in where should we keep the `upgradeTo(address)` function, we have two choices that are either keep it in the `Proxy Contract` which is essentially how `Transparent Proxy Pattern` works, or keep it in the `Implementation Contract` which is how the UUPS contract works.

![](https://i.imgur.com/KVY1nHq.png)

Another important thing to note about this `Proxy pattern` is that the constructor of the `Implementation Contract` is never executed.

When deploying a new smart contract, the code inside the constructor is not a part of the contract's runtime bytecode because it is only needed during the deployment phase and runs only once. Now because when `Implementation Contract` was deployed it was initially not connected to the `Proxy Contract` as a reason any state change that would have happened in the constructor is now not there in the `Proxy Contract` which is used to maintain the overall state.

As a reason `Proxy Contracts` are unaware of the existence of constructors. Therefore, instead of having a constructor, we use something called an `initializer` function which is called by the `Proxy Contract` once the `Implementation Contract` is connected to it. This function does exactly what a constructor is supposed to do but is now included in the runtime bytecode as it behaves like a regular function and is callable by the `Proxy Contract`.

Using OpenZeppelin contracts, you can use their `Initialize.sol` contract which makes sure that your `initialize` function is executed only once just like a contructor

```solidity
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContract is Initializable {
    function initialize(
        address arg1,
        uint256 arg2,
        bytes memory arg3
    ) public payable initializer {
        // "constructor" code...
    }
}
```

Above given code is from [Openzeppelin's documentation](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat) and provides an example of how the `initializer` modifier ensures that the `initialize` function can only be called once. This modifier comes from the `Initializable Contract`

We will now study Proxy patterns in detail 🚀 👀

Lets goo!!!!

## Transparent Proxy Pattern

The Transparent Proxy Pattern is a simple way to separate responsibilities between `Proxy` and `Implementation` contracts. In this case, the `upgradeTo` function is part of the `Proxy` contract, and the `Implementation` can be upgraded by calling `upgradeTo` on the proxy thereby changing where future function calls are delegated to.

There are some caveats though. There might be a case where the `Proxy Contract` and `Implementation Contract` have a function with the same name and arguments. Imagine if `Proxy Contract` has a `owner()` function and so does `Implementation Contract`. In Transparent Proxy contracts, this problem is dealt by the `Proxy` contract which decides whether a call from the user will execute within the `Proxy` contract itself or the `Implementation Contract` based on the `msg.sender` global variable

So if the `msg.sender` is the admin of the proxy then the proxy will not delegate the call and will try to execute the call if it understands it. If it's not the admin address, the proxy will delegate the call to the `Implementation Contract` even if the matches one of the proxy's functions.

## Issues with Transparent Proxy Pattern

As we know that the address of the `owner` will have to be stored in the storage and using storage is one of the most inefficient and costly steps in interacting with a smart contract every time the user calls the proxy, the proxy checks whether the user is the admin or not which adds unnecessary gas costs to majority of the transactions taking place.

## UUPS Proxy Pattern

The UUPS Proxy Pattern is another way to separate responsibilities between `Proxy` and `Implementation` contracts. In this case, the `upgradeTo` function is also part of the `Implementation` contract, and is called using a `delegatecall` through the Proxy by the owner.

In UUPS whether its the admin or the user, all the calls are sent to the `Implementation Contract` The advantage of this is that every time a call is made we will not have to access the storage to check if the user who started the call is an admin or not which improved efficiency and costs. Also because its the `Implementation Contract` you can customize the function according to your need by adding things like `Timelock`, `Access Control` etc with every new `Implementation` that comes up which couldn't have been done in the `Transparent Proxy Pattern`

## Issues with UUPS Proxy Pattern

The issue with this is now because the `upgradeTo` function exists on the side of the `Implementation contract` developer has to worry about the implementation of this function which may sometimes be complicated and because more code has been added, it increases the possibility of attacks. This function also needs to be in all the versions of `Implementation Contract` which are upgraded which introduces a risk if maybe the developer forgets to add this function and then the contract can no longer be upgraded.

## BUIDL

Lets build an example where you can experience how to build an upgradeable contract. We will be using the UUPS upgradeability pattern through this example, though you can build one with the Transparent Proxy Pattern as well!

- To setup a Hardhat project, Open up a terminal and execute these commands

  ```bash
  npm init --yes
  npm install --save-dev hardhat
  ```

- If you are on Windows, please do this extra step and install these libraries as well :)

  ```bash
  npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
  ```

- In the same directory where you installed Hardhat run:

  ```bash
  npx hardhat
  ```

  - Select `Create a basic sample project`
  - Press enter for the already specified `Hardhat Project root`
  - Press enter for the question on if you want to add a `.gitignore`
  - Press enter for `Do you want to install this sample project's dependencies with npm (@nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers)?`

Now you have a hardhat project ready to go!

- We will be using libraries from openzeppelin which support upgradeable contracts. To install those libraries, in the same folder execute the following command:

```bash
npm i @openzeppelin/contracts-upgradeable @openzeppelin/hardhat-upgrades @nomiclabs/hardhat-etherscan --save-dev
```

Replace the code in your `hardhat.config.js` with the following code to be able to use these libraries:

```javascript
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: "0.8.4",
};
```

Start by creating a new file inside the `contracts` directory called `LW3NFT.sol` and add the following lines of code to it

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract LW3NFT is Initializable, ERC721Upgradeable, UUPSUpgradeable, OwnableUpgradeable   {
    // Note how we created an initialize function and then added the
    // initializer modifier which ensure that the
    // initialize function is only called once
    function initialize() public initializer  {
        // Note how instead of using the ERC721() constructor, we have to manually initialize it
        // Same goes for the Ownable contract where we have to manually initialize it
        __ERC721_init("LW3NFT", "LW3NFT");
        __Ownable_init();
        _mint(msg.sender, 1);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {

    }
}
```

Lets try to understand what's happening in this contract in a bit more detail

If you look at all the contracts which `LW3NFT` is importing, you will realize why they are important. First being the `Initializable` contract from Openzeppelin which provides us with the `initializer` modifier which ensures that the `initialize` function is only called once. The `initialize` function is needed because we cant have a contructor in the `Implementation Contract` which in this case is the `LW3NFT` contract

It imports `ERC721Upgradeable` and `OwnableUpgradeable` because the original `ERC721` and `Ownable` contracts have a constructor which cant be used with proxy contracts.

Lastly we have the `UUPSUpgradeable Contract` which provides us with the `upgradeTo(address)` function which has to be put on the `Implementation Contract` in case of a `UUPS` proxy pattern.

After the declaration of the contract, we have the `initialize` function with the `initializer` modifier which we get from the `Initializable` contract.
The `initializer` modifier ensures the `initialize` function can only be called once. Also note that the new way in which we are initializing `ERC721` and `Ownable` contract. This is the standard way of initializing upgradeable contracts and you can look at the function [here](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC721/ERC721Upgradeable.sol#L45).
After that we just mint using the usual mint function.

```solidity
function initialize() public initializer  {
    __ERC721_init("LW3NFT", "LW3NFT");
    __Ownable_init();
    _mint(msg.sender, 1);
}
```

Another interesting function which we dont see in the normal `ERC721` contract is the `_authorizeUpgrade` which is a function which needs to be implemented by the developer when they import the `UUPSUpgradeable Contract` from Openzeppelin, it can be found [here](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol#L100). Now why this function has to be overwritten is intresting because it gives us the ability to add authorization on who can actually upgrade the given contract, it can be changed according to requirements but in our case we just added an `onlyOwner` modifier.

```solidity
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {

    }
```

Now lets create another new file inside the `contracts` directory called `LW3NFT2.sol` which will be the upgraded version of `LW3NFT.sol`

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LW3NFT.sol";

contract LW3NFT2 is LW3NFT {

    function test() pure public returns(string memory) {
        return "upgraded";
    }
}
```

This smart contract is much easier because it is just inheriting `LW3NFT` contract and then adding a new function called `test` which just returns a string `upgraded`.

Pretty easy right? 🤯

Wow 🙌 , okay we are done with writing the `Implementation Contract`, do we now need to write the `Proxy Contract` as well?

Good news is nope, we dont need to write the `Proxy Contract` because `Openzeppelin` deploys and connects a `Proxy Contract` automatically when we use their library to deploy the `Implementation Contract`.

So lets try to do that, In your `test` directory create a new file named `proxy-test.js` and lets have some fun with code

```solidity
const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("ERC721 Upgradeable", function () {
  it("Should deploy an upgradeable ERC721 Contract", async function () {
    const LW3NFT = await ethers.getContractFactory("LW3NFT");
    const LW3NFT2 = await ethers.getContractFactory("LW3NFT2");

    let proxyContract = await hre.upgrades.deployProxy(LW3NFT, {
      kind: "uups",
    });
    const [owner] = await ethers.getSigners();
    const ownerOfToken1 = await proxyContract.ownerOf(1);

    expect(ownerOfToken1).to.equal(owner.address);

    proxyContract = await hre.upgrades.upgradeProxy(proxyContract, LW3NFT2);
    expect(await proxyContract.test()).to.equal("upgraded");
  });
});

```

Lets see whats happening here, We first get the `LW3NFT` and `LW3NFT` instance using the `getContractFactory` function which is common to all the levels we have been teaching till now. After that the most important line comes in which is:

```solidity
let proxyContract = await hre.upgrades.deployProxy(LW3NFT, {
  kind: "uups",
});
```

This function comes from the `@openzeppelin/hardhat-upgrades` library that you installed, It essentially uses the upgrades class to call the `deployProxy` function and specifies the kind as `uups`. When the function is called it deploys the `Proxy Contract`, `LW3NFT Contract` and connects them both. More info about this can be found [here](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-hardhat-upgrades).

Note that the `initialize` function can be named anything else, its just that `deployProxy` by default calls the function with name `initialize` for the initializer but you can modify it by changing the defaults 😇

After deploying, we test that the contract actually gets deployed by calling the `ownerOf` function for Token ID 1 and checking if the NFT was indeed minted.

Now the next part comes in where we want to deploy `LW3NFT2` which is the upgraded contract for `LW3NFT`.

For that we execute the `upgradeProxy` method again from the `@openzeppelin/hardhat-upgrades` library which upgrades and replaces `LW3NFT` with `LW3NFT2` without changing the state of the system

```javascript
proxyContract = await hre.upgrades.upgradeProxy(deployedLW3NFT, LW3NFT2);
```

To test if it was actually replaced we call the `test()` function, and ensured that it returned `"upgraded"` even though that function wasn't present in the original `LW3NFT` contract.

Here you go, you learn how to upgrade a smart contract today.

LFG 🚀

## Readings

- `Timelock` was mentioned in the given article, to learn more about it you can read the [following article](https://blog.openzeppelin.com/protect-your-users-with-smart-contract-timelocks/)
- `Access Control` was also mentioned and you can read about it more [here](https://docs.openzeppelin.com/contracts/3.x/access-control)

## References

- [OpenZeppelin Docs](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies)
- [OpenZeppelin Youtube](https://www.youtube.com/watch?v=kWUDTZhxKZI)
