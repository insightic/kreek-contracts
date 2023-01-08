# Kreek Contracts

![kreek](https://avatars.githubusercontent.com/u/121073430?s=96&v=4)

![node](https://img.shields.io/badge/node-v10.15.3-green)
![npm](https://img.shields.io/badge/npm-v6.9.0-green)
![solidity](https://img.shields.io/badge/solidity-0.8.13-brightgreen)
![license](https://img.shields.io/github/license/kreekapp/kreek-contracts)
![contributors](https://img.shields.io/github/contributors/kreekapp/kreek-contracts)

## What is Kreek?

Kreek is a Dollar-cost averaging (DCA) dApp. DCA is a popular investment strategy that involves buying a fixed dollar amount of a particular asset at regular intervals, regardless of the price. This approach can be particularly beneficial for those looking to invest in volatile assets such as cryptocurrency.

There are several reasons why DCA is considered a good strategy for crypto investors. First and foremost, it helps to mitigate risk by allowing you to average out your purchase price over time. Rather than trying to time the market and potentially buying at a high price, DCA allows you to steadily accumulate assets at a variety of price points.

Additionally, DCA can be a great way to build a long-term investment portfolio. By consistently purchasing assets on a regular basis, you can take advantage of compound interest and potentially see significant growth over time.

Furthermore, DCA can help to alleviate some of the psychological pressures that come with investing. It can be tempting to try to time the market and make impulsive buying and selling decisions based on short-term price fluctuations. DCA takes the emotion out of the equation by adhering to a predetermined plan.

In conclusion, dollar-cost averaging is a sound strategy for those looking to invest in cryptocurrency. It helps to mitigate risk, build a long-term portfolio, and alleviate psychological pressures.

## Kreek Contracts Overview

### Main Contracts

1. `Kreek.sol` is a NFT and also the main contract responsible for managing user assets and rewards DCA users.
2. `Vesting.sol` is to vest the DCA rewards back to the users in a reasonable and sound way.
3. `TimelockController.sol` is responsible to safeguard Kreek from malicious actors.

### Layout

```shell
├───script
├───src
│   ├───interfaces
│   │   ├─── ...
│   ├───nfts
│   │   ├─── ...
│   └───utils
│       ├─── ...
└───test
```

### Architecture 
** Put Some Diagram here**

## Quick Commands

```shell
forge install
forge remappings
forge flatten <File>
forge fmt
forge tree
```

## Slither - Security Analyzer

`pip3 install slither-analyzer` and
`slither .` inside the repo.

We also recommend to install the [slither vscode extension](https://marketplace.visualstudio.com/items?itemName=trailofbits.slither-vscode).

Run it after major changes and ensure there arent any warnings / errors.

To disable slither, you can add `// slither-disable-next-line DETECTOR_NAME`.

You can find `DETECTOR_NAME` [here](https://github.com/crytic/slither/wiki/Detector-Documentation).

## Surya - GraphViz for Architecture

Install Surya using : `npm install -g surya`

To create a graphviz summary of all the function calls do, `surya graph contracts/**/*.sol > FM_full.dot` and open `FM_full.dot` using a graphviz plugin on VSCode.

`surya describe contracts/**/*.sol` will summarize the contracts and point out fn modifiers / payments. It's useful to get an overview.

You can see further instructons for Surya [here](https://github.com/ConsenSys/surya).