![Cover](.github/cover.png)

# Haven1 Testnet Developer Template

Welcome to the Haven1 Testnet Developer Template repository! This repository
serves as a guide for developers aiming to build smart contracts on the Haven1
Testnet. Whether you are a beginner or an experienced developer, this repository
will provide you with best practices, style recommendations, and examples to
streamline your smart contract development process.

Kindly be advised that the Haven1 development team continuously conducts
rigorous testing and refinement of all smart contracts included in this
repository. The team does not guarantee future compatibility of these contracts.
Any future updates to this repository will be properly versioned and tagged for
clarity.

This repository utilises [Hardhat](https://hardhat.org) as the base for its
development environment. The Hardhat [documentation can be found here](https://hardhat.org/docs)
and a [tutorial can be found here](https://hardhat.org/tutorial).

## Table of Contents

-   [Introduction](#introduction)
-   [Permissioned Deployments](#permissioned-deployments)
-   [Vendor Contracts](#vendor)
    -   [H1 Developed Application](#vendor-dev-app)
    -   [Proof of Identity](#vendor-poi)
-   [Example Contracts](#examples)
    -   [Simple Storage](#examples-storage)
    -   [NFT Auction](#examples-auction)
-   [Development](#dev)
    -   [Prerequisites](#dev-pre)
    -   [Installation](#dev-install)
    -   [Project Structure](#dev-dirs)
    -   [Testing and Coverage](#dev-testing)
    -   [Local Deployment](#dev-local-deploy)
    -   [Preparing for Testnet Deployment](#dev-testnet-deploy)
-   [Contract Submission and Review](#submission)
-   [Feedback](#feedback)

<a id="introduction"></a>

## Introduction

Haven1 is an EVM-compatible Layer 1 blockchain that seamlessly incorporates key
principles of traditional finance into the Web3 ecosystem.

The Haven1 Testnet provides a sandbox environment for developers to experiment
with building applications on the Haven1 network, along with an opportunity to
interact with a number of our unique features. This repository aims to assist
developers in writing secure, efficient, and maintainable smart contracts that
will be suitable for deployment on the Haven1 Testnet.

It provides the essential set of vendor (Haven1) contracts that developers will
need to facilitate testing and development, as well as two (2) example contracts
(a Simple Storage contract and an NFT Auction) that implement and interface with
these vendor contracts.

It provides a full testing suite with a number of helpful utility functions,
deployment scripts and tasks.

All code included in this repository has been extensively commented to make
it self-documenting and easy to comprehend.

The code within this repository establishes the expected quality for any code
submitted for review and deployment to the Haven1 Testnet. We are dedicated to
maintaining high standards of code quality, security, and maintainability across
all smart contracts deployed on the network.

<a id="permissioned-deployments"></a>

## Permissioned Deployments

On the Haven1 Mainnet, before a contract will be considered for deployment it
must have undergone two (2) rounds of formal audit (performed by Haven1's
trusted audit partners) and be submitted to the Haven1 Association for review.
Upon successful review, _the Haven1 Association will deploy the contract on
behalf of the developer_. This process ensures a) that all contracts adhere to
the standards set by Haven1 and b) will have undergone scrutiny for security and
functionality before being deployed on the network.

To aid in the developer experience, Haven1 have authored a contract,
`H1DevelopedApplication`, that all third-party contracts deployed to the network
must implement (see [below](#vendor-dev-app) for further information on the
`H1DevelopedApplication` contract).

It, in essence, standardizes aspects of the contract deployment and upgrade
process, provides an avenue for developers to set function-specific fees,
establishes contract privileges and ensures the interoperability and
compatibility of the contract within the broader ecosystem.

For the purposes of Testnet, developers will not need their contracts audited
prior to deployment. Rather, they must simply submit their contracts to the
Haven1 Association for review. Developers _will still be required_ to implement
the `H1DevelopedApplication` contract on all contracts they seek to deploy.
Upon successful review, the _Haven1 Association will deploy the contracts to the
Haven1 Testnet on behalf of the developer_.

For further requirements, see [Preparing for Testnet Deployment](#dev-testnet-deploy).

For contract submission details, see [Contract Submission and Review](#submission).

<a id="vendor"></a>

## Vendor Contracts

This repository contains a number of vendor contracts - contracts written by
Haven1 - that are located in `./contracts/vendor/*`.

These contracts provide the necessary foundation that developers will need to
facilitate local smart contract development. Of these contracts, developers
**must** implement the `H1DevelopedApplication` contract in each contract they
seek to deploy, and may choose to interact with the `ProofOfIdentity` contract.
Accordingly, an overview of each contract is provided below. The API
documentation can be found in `./vendor-docs/*`.

<a id="vendor-dev-app"></a>

### H1 Developed Application

At the core of the developer experience on Haven1 is the `H1DevelopedApplication`
contract. It serves as the entry point into the Haven1 ecosystem for developers
looking to deploy smart contract applications on Haven1.

#### What it Does

`H1DevelopedApplication` standardizes the following:

-   Establishing privileges;
-   Pausing and unpausing the contract;
-   Upgrading the contract;
-   Assigning developer fees to functions; and
-   Handling the payment of those fees.

#### Privileges

`H1DevelopedApplication` implements Open Zeppelin's `AccessControl` to establish
privileges on the contract.

The contract establishes the following roles:

-   `DEFAULT_ADMIN_ROLE`: Upon contract initialization, this role is assigned
    to the `Haven1 Association`.

-   `PAUSER_ROLE`: Upon contract initialization, this is set to the `Haven1
Association` as well as the developer account.

-   `UNPAUSER_ROLE`: Upon contract initialization, this is set to the `Haven1
Association`.

-   `DEV_ADMIN_ROLE`: Upon contract initialization, this is set to the
    developer's address for use in the inheriting contract.

#### Pausing and Unpausing the Contract

`H1DevelopedApplication` implements Open Zeppelin's `Pausable` to establish the
ability to pause and unpause the contract.

The APIs for both pausing and unpausing are provided by the contract. The
`whenNotPaused` modifier _must_ be included on any function that mutates state
(that is, any "write" function).

As noted above, the `H1DevelopedApplication` contract establishes a `PAUSER_ROLE`
and `UNPAUSER_ROLE` role.

-   The `PAUSER_ROLE` role is shared by the `Haven1 Association` and the
    developer. These accounts have the ability to pause the contract.

-   The `UNPAUSER_ROLE` role is assigned **only** to the `Haven1 Association`.
    This account has the ability to unpause the contract.

#### Upgrading the Contract

`H1DevelopedApplication` implements Open Zeppelin's `UUPSUpgradeable` and
`Initializable` to establish the ability to upgrade the contract.

Only the `Haven1 Association`, by virtue of the roles outlined above, will have
the ability to upgrade a contract.

#### Assigning Fees

`H1DevelopedApplication` allows the developer to assign a fee (within the
minimum and maximum constraints provided by the `FeeContract`) to particular
functions. Assigning fees to functions can be requested by the developer at any
stage, however they must first be approved by the `Haven1 Association` before
they take effect.

#### Taking Fees

`H1DevelopedApplication` exposes a modifier (`developerFee`) that is to be
attached to any function that has a fee associated with it. This modifier will
handle the fee logic.
**IMPORTANT:** Contracts that store native H1 should **never** elect to refund
the remaining balance when using the `developerFee` modifier as it will send the
contract's balance to the user.

<a id="vendor-poi"></a>

### Proof of Identity

Among the features introduced by Haven1 is the Provable Identity Framework. This
framework enhances security and unlocks previously unattainable decentralized
finance use cases, marking a significant advancement in the convergence of
traditional financial principles and decentralized technologies.

All Haven1 users will be required to complete identity verification to deter
illicit activity and enable recourse mechanisms on transactions. Once completed,
users will receive a non-transferable NFT containing anonymized information that
developers on Haven1 can utilize to permission their apps and craft novel
blockchain use cases. The `ProofOfIdentity` is responsible for setting /
updating this user information and handling the NFT issuance.

Currently tracked attributes, their ID and types:

| ID  | Attribute         | Type    | Example Return |
| --- | ----------------- | ------- | -------------- |
| 0   | primaryID         | bool    | true           |
| 1   | countryCode       | string  | "sg"           |
| 2   | proofOfLiveliness | bool    | true           |
| 3   | userType          | uint256 | 1              |
| 4   | competencyRating  | uint256 | 88             |

Each attribute will also have a corresponding `expiry` and an `updatedAt`
field.

The following fields are guaranteed to have a non-zero entry for users who
successfully completed their identity check:

-   `primaryID`;
-   `countryCode`;
-   `proofOfLiveliness`; and
-   `userType`.

Note that while this contract is upgradable, provisions have been made to
allow attributes to be added without the need for upgrading. An event will be
emitted (`AttributeAdded`) if an attribute is added. If an attribute is added
but the contract has not been upgraded to provide a new explicit getter,
you can use one of the four (4) generic getters to retrieve the information.

-   `getStringAttribute`;
-   `getU256Attribute`;
-   `getBoolAttribute`; and
-   `getBytesAttribute`.

**If you have a use case that requires an identity attribute that is not currently
available, please do not hesitate to [contact us](here) with your feedback and
request!**

<a id="examples"></a>

## Example Contracts

This repository provides two (2) example contracts:

1.  `SimpleStorage`; and
2.  `NFTAuction`.

These contracts, located under `./contracts/examples/*`, serve as educational
resources and reference implementations for developers to aid in understanding
the integration of the `H1DevelopedApplication` contract and interaction with
the `ProofOfIdentity` contract.

The example implementations of the `H1DevelopedApplication` showcased here are
considered canonical and demonstrates best practices for initializing upgradable
contracts. Any contracts submitted for review to the Haven1 Association must
follow this pattern.

<a id="examples-storage"></a>

### Simple Storage

The first example contract provided is the `SimpleStorage` contract
(`./contracts/examples/simple-storage/SimpleStorage.sol`). It is a minimal
contract that demonstrates storing and retrieving data on a blockchain. It
implements the `H1DevelopedApplication` contract in an idiomatic manner,
ensuring correct constructor and initialization strategies.

It sets two (2) developer fees: one on the `incrementCount` function, and one on
the `decrementCount` function. It further illustrates an example use case of the
access control APIs that are exposed via the `H1DevelopedApplication` contract.

The tests and setup for this contract can be found in `./test/simple-storage/*`.
Reusable utility functions for this contract (such as the contract's deployment)
can be found in `./utils/deploy/simple-storage/deploySimpleStorage.ts`. We
encourage developers to follow this pattern of separation of concerns.

Developers can utilize this contract and its associated tests and utilities
as a starting point to understand the fundamental principles of developing
contracts for the Haven1 Network.

To see a live demonstration of this Simple Storage contract, see our
[Developer Fees](https://www.haven1.org/fees/developer-fee) testnet page.

<a id="examples-auction"></a>

### NFT Auction

The second example contract provided is the `NFTAuction` contract
(`./contracts/examples/nft-auction/NFTAuction.sol`). This contract facilitates
the auction of a single NFT and demonstrates slightly more complex, but very
digestible, logic. It implements the `H1DevelopedApplication` contract in the
same manner as the `SimpleStorage` contract. Furthermore, it interfaces with the
`ProofOfIdentity` contract to permission access to the auction.

The tests and setup for this contract can be found in `./test/nft-auction/*`.
Reusable utility functions for this contract (such as the contract's deployment)
can be found in `./utils/deploy/nft-auction/deployNFTAuction.ts`. We
encourage developers to follow this pattern of separation of concerns.

<a id="dev"></a>

## Development

This section outlines everything you will need to get your local development
environment up and running. Before diving into the installation process, ensure
you have the necessary prerequisites installed on your system. Once you are
ready, follow the steps below to complete the setup of your environment.

<a id="dev-pre"></a>

### Prerequisites

-   [Node 18](https://nodejs.org/en)

<a id="dev-install"></a>

### Installation

1.  Clone the repository

    ```bash
    git clone git@github.com:haven1network/dev-onboarding-template.git
    ```

2.  Navigate to the repository

    ```bash
    cd path/to/repo
    ```

3.  Reinitialize git: Ensure you are in the Haven1 Developer Testnet directory
    before running this command - it will delete the `.git` directory!

    ```bash
    echo -n "Confirm .git reinit: " \
    && read ans && [ ${ans:-N} = y ] \
    && rm -rf .git && git init
    ```

4.  Install dependencies

    ```bash
    npm i
    ```

5.  Create `.env`

    ```bash
    cp .env.example .env
    ```

6.  Compile contracts and generate types
    ```bash
    npx hardhat compile
    ```

<a id="dev-dirs"></a>

### Project Structure

The following top-level directory tree highlights the general project structure
and annotates important directories for clarity.

```bash
.
├── .env.example
├── .eslintignore
├── .eslintrc.js
├── .git
├── .github
├── .gitignore
├── .prettierignore
├── .prettierrc
├── .solcover.js
├── README.md
├── artifacts           # Hardhat compilation artifacts
├── cache               # Hardhat cached files
├── contracts           # Source files for contracts
├── deployment_data     # Holds contract deployment data (e.g., contract addresses)
├── environment.d.ts    # TypeScript declaration file for environment variables
├── hardhat.config.ts   # Configuration file for the Hardhat development environment
├── node_modules
├── package-lock.json
├── package.json
├── scripts             # Workflow automations (e.g., deployment scripts)
├── tasks               # Workflow automations (e.g., verifying contracts, setting permissions)
├── templates
├── test                # All project tests
├── tsconfig.json
├── typechain-types     # Output directory for contract type definitions
└── utils               # Various reusable utility / helper functions

```

<a id="dev-testing"></a>

### Testing and Coverage

As highlighted above, tests are located and written in the `./test/*` directory.
All tests relating to a specific contract should be located in a sub-directory
therein and follow the `*.test.ts` naming convention. See the below example.

```bash
./test
├── constants.ts            # Reusable test specific constants (vendor contract errors, time etc)
├── nft-auction             # Tracks with contract name
│   ├── auction.test.ts     # Test file
│   └── setup.ts            # Test specific setup file
└── simple-storage
    ├── setup.ts
    └── simpleStorage.test.ts

```

-   To run tests: `npm test`.
-   To run coverage: `npm run coverage`. Will output coverage results in `./coverage`.

<a id="dev-local-deploy"></a>

### Local Deployment

The repository provides a local deployment script, found under
`./scripts/deployLocal.ts`, to aid to fast-tracking your developer experience.

This script contains all the setup steps for deploying the required vendor
contracts and the two (2) example contracts. It is in here that developers
can add the logic to deploy their own contracts.

To deploy locally:

1.  In one terminal instance, run the `npx hardhat node` command.
2.  In a separate terminal instance, run the `npm run deploy:local` command.

Upon successful local deployment, the contract addresses will be written to
`./deployment_data/local/*`.

<a id="dev-testnet-deploy"></a>

### Preparing for Testnet Deployment

There are a number of important considerations that a developer must be aware of
when preparing their contracts for submission to the Haven1 Association.

Haven1 is principally concerned with maintaining high standards of code quality,
security, and maintainability across all smart contracts deployed on the network.
Projects that do not meet the requisite standards will be unable to deploy on the
Haven1 Testnet.

For ease of reference, these considerations will be broken down into points below:

1.  Ensure all contracts implement the `H1DevelopedApplication` contract
    in a manner consistent with the provided example contracts (including correct
    implementation of the `whenNotPaused` modifier on any functions that modify
    state / write functions). If any contracts do not correctly implement the
    `H1DevelopedApplication` contract or are not being correctly initialized,
    the request to deploy will be denied.

2.  Ensure all contracts adhere to the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html).
    Contracts that materially deviate from this style guide will be not be
    considered for deployment (for example, 4 space indenting, preferring 80
    character line length and not exceeding 120,
    [correct ordering of functions](https://docs.soliditylang.org/en/latest/style-guide.html#order-of-functions)
    and so on).

3.  Ensure all contracts are thoroughly tested and that the test logic is clear
    and documented where necessary. Tests should follow the provided structure.
    If a project is submitted with insufficiently robust tests, if testing logic
    is not clear, or tests do not pass, the request to deploy will be denied.
    A good rule of thumb is always to prefer making code easy to read and
    understand, not just easy to write.

4.  Continue to use Typescript for any supporting code that is written. Please
    ensure strict typing of all supporting code. This will make your codebase
    easier and faster to inspect and will provide you with a greater chance of
    a successful review.

5.  Ensure every effort is made to thoroughly document your code. Whether that
    is via [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html)
    for your smart contracts, or [JSDoc](https://jsdoc.app) (where required)
    for your Typescript code. This will make your codebase easier and faster to
    inspect and will provide you with a greater chance of a successful review.

6.  Ensure deployment functions for any contracts that you wish to deploy are
    included in `./utils/deploy/*` in a manner consistent with the examples.
    Ensure that these functions are then brought in to the
    `./scripts/deployTestnet.ts` and `./scripts/deployLocal.ts` files and called
    in a manner consistent with the examples. Before deploying to Testnet, Haven1
    will deploy your contracts locally to ensure everything runs smoothly.
    Any contracts that do not have a corresponding deployment function or an
    incorrect configuration will not be deployed.
    Note that on `L54` of the `deployTestnet.ts` file, there is an array
    initialised, called `REQUIRED_VARS`, that holds the required environment
    variables for the deployment. Please be sure to add any environment variables
    that your deployment is dependant on to this array to ensure there are no
    issues.

7.  If your project requires additional environment variables, please be sure to
    include them in the `.env.example` and the `environment.d.ts`. If the
    necessary environment variables are not supplied, we will be unable to deploy
    your contracts.

8.  Ensure every effort is made to remain consistent with the suggested project
    layout. This will make your codebase easier and faster to inspect, providing
    you with a higher chance of a successful review.

9.  Please feel free to override this README and use it to include any important
    information about your project!

10. If an attempt is made to include any malicious code, your account will be
    suspended and you will be excluded from any potential airdrop events.

<a id="submission"></a>

## Contract Submission and Review

To submit your contract for review, please follow these steps:

1.  Fork / clone this repository.

2.  Write your smart contract following the best practices and style guide
    recommendations provided in this repository, ensuring adherence to the
    above requirements.

3.  Once your contract is ready for review, email us a link to your public
    repository for review. Be sure to include your Haven1 verified wallet
    address that you wish to use as the contract admin. Email: `contact@haven1.org`.

4.  Our team will review your contract for security, efficiency, and adherence
    to coding standards.

5.  Upon successful review, we will deploy your contract on the Haven1 Testnet
    and notify of you the process and specifics (deployed contract addresses,
    etc). We will also PR the deployment data to your public repository.

Please note that contracts not meeting our standards will require revisions
before deployment. We aim to provide constructive feedback to help you improve
your contract's quality and security.

<a id="feedback"></a>

## Feedback

We highly value your input and strive to continuously enhance both your
experience with Haven1 and the overall developer environment. Whether your
feedback pertains to this repository, your interactions with Haven1, or any
general suggestions, please do not hesitate to submit it to us at
`contact@haven1.org`.

Each submission will be carefully reviewed, and your insights will be
instrumental in our ongoing efforts to refine Haven1 and optimize the developer
journey. Thank you for helping us build a better platform together.

