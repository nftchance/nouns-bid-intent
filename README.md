# Nouns Acount House Bid Intents

This repository contains a trustless scheduled bid protocol that consumes the [Emporium framework](https://github.com/nftchance/emporium).

Powered by gasless transaction declarations, scheduled bids are enabled with a relay network ran by the provider.

## Getting Started

If you are not a developer or are simply looking for the live application, head [here]().

Otherwise, welcome to the developer documentation! The base implementation is extremely simple so there isn't much for you to dig into here.


### Installing the Dependencies

When you are ready go ahead and open your terminal to run:

```bash
pnpm install
```

Everything has already been configured, you do not need to configure an environment file unless you plan on deploying an instance of the protocol (which you should never need to do.)

### Running the Tests

The base framework has been built upon `hardhat` which means you can make sure everything is setup by running:

```bash
pnpm hardhat test
```

### Deploying

Nouns [Major] is deployed on Mainnet. Due to this, the protocol is designed to only support Ethereum Mainnet. 

```
pnpm hardhat run src/scripts/deploy.ts
```

While this protocol was designed to support Nouns [Major] there are several forks and sub-DAOs. Due to this, it may be the case that this protocol works on other Auction Houses. If you are unsure, please operate with caution.

The protocol will support any Nouns Auction House on the deployed chain and you only need to deploy a new instance if you are operating on a new chain. When deploying, everything happens through a CREATE2 deployment so that the contract address will remain consistent across all chains that it is deployed on. If you deploy a new instance, please submit a PR.