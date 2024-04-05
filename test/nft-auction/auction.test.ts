/* IMPORT NODE MODULES
================================================== */
import {
    loadFixture,
    time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers, upgrades } from "hardhat";
import { expect } from "chai";

/* IMPORT CONSTANTS, TYPES AND UTILS
================================================== */
import {
    type IssueIdArgs,
    type UserTypeKey,
    NFTAuctionTest,
    auctionErr,
    userType,
} from "./setup";
import {
    DAY_SEC,
    ZERO_ADDRESS,
    accessControlErr,
    h1DevelopedErr,
    initialiazbleErr,
    pausableErr,
} from "../constants";
import { addTime } from "@utils/time";
import { getH1Balance, parseH1 } from "@utils/token";
import { PROOF_OF_ID_ATTRIBUTES } from "@utils/deploy/proof-of-identity";
import { tsFromTxRec } from "@utils/transaction";
import { fnSelector } from "@utils/fnSelector";
import {
    type NFTAuctionInitalizerArgs,
    deployNFTAuction,
    AuctionConfig,
    getAuctionKind,
} from "@utils/deploy/nft-auction";

/* TESTS
================================================== */
describe("NFT Auction", function () {
    /* Setup
    ======================================== */
    const fnSel = fnSelector("bid()");
    const exp = addTime(Date.now(), 2, "years", "sec");

    function newArgs(addr: string, userTypeKey: UserTypeKey): IssueIdArgs {
        return {
            account: addr,
            userType: userType(userTypeKey),
            proofOfLiveliness: true,
            primaryID: true,
            countryCode: "sg",
            expiries: [exp, exp, exp, exp],
            tokenURI: "test-uri",
        };
    }

    async function setup() {
        return await NFTAuctionTest.create();
    }

    /* Deployment and Initialization
    ======================================== */
    describe("Deployment and Initialization", function () {
        it("Should have a deployment address", async function () {
            const t = await loadFixture(setup);
            expect(t.auctionContractAddress).to.have.length(42);
            expect(t.auctionContractAddress).to.not.equal(ZERO_ADDRESS);
        });

        it("Should correctly set the auction kind", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionInitializerArgs.auctionConfig;
            const auctionType = await t.auctionContract.getAuctionKind();
            expect(auctionType).to.equal(cfg.kind);
        });

        it("Should correctly set the auction length", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionInitializerArgs.auctionConfig;
            const auctionLength = await t.auctionContract.getAuctionLength();
            expect(auctionLength).to.equal(cfg.length);
        });

        it("Should correctly set the starting bid", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionInitializerArgs.auctionConfig;
            const startingBid = await t.auctionContract.getHighestBid();
            expect(startingBid).to.equal(cfg.startingBid);
        });

        it("Should correctly set the prize NFT address and ID", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionInitializerArgs.auctionConfig;
            const [addr, id] = await t.auctionContract.getNFT();
            expect(addr).to.equal(cfg.nft);
            expect(id).to.equal(cfg.nftID);
        });

        it("Should correctly set the auction beneficiary address and ID", async function () {
            const t = await loadFixture(setup);
            const cfg = t.auctionInitializerArgs.auctionConfig;
            const b = await t.auctionContract.getBeneficiary();
            expect(b).to.equal(cfg.beneficiary);
            expect(b).to.equal(t.auctionInitializerArgs.developer);
        });

        it("Should fail to init if the fee contract address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                feeContract: ZERO_ADDRESS,
            };

            const err = auctionErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association, 0)
            ).to.be.revertedWithCustomError(t.auctionContract, err);
        });

        it("Should fail to init if the poi address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                proofOfIdentity: ZERO_ADDRESS,
            };

            const err = auctionErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association, 0)
            ).to.be.revertedWithCustomError(t.auctionContract, err);
        });

        it("Should fail to init if the association address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                association: ZERO_ADDRESS,
            };

            const err = auctionErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association, 0)
            ).to.be.revertedWithCustomError(t.auctionContract, err);
        });

        it("Should fail to init if the dev address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                developer: ZERO_ADDRESS,
            };

            const err = auctionErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association, 0)
            ).to.be.revertedWithCustomError(t.auctionContract, err);
        });

        it("Should fail to init if the fee collector address is the zero address", async function () {
            const t = await loadFixture(setup);
            const args: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                feeCollector: ZERO_ADDRESS,
            };

            const err = auctionErr("ZERO_ADDRESS");

            await expect(
                deployNFTAuction(args, t.association, 0)
            ).to.be.revertedWithCustomError(t.auctionContract, err);
        });

        it("Should fail to init if an auction kind of zero (0) is supplied ", async function () {
            const t = await loadFixture(setup);
            const kind = 0;
            const args = t.auctionInitializerArgs;
            const cfg = { ...args.auctionConfig, kind };
            const err = auctionErr("INVALID_AUCTION_KIND");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.feeContract,
                        args.proofOfIdentity,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(0);
        });

        it("Should fail to deploy if an auction kind greater than three (3) is supplied ", async function () {
            const t = await loadFixture(setup);
            const kind = 4;
            const args = t.auctionInitializerArgs;
            const cfg = { ...args.auctionConfig, kind };
            const err = auctionErr("INVALID_AUCTION_KIND");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.feeContract,
                        args.proofOfIdentity,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(kind);
        });

        it("Should fail to deploy if an invalid auction length is supplied", async function () {
            const t = await loadFixture(setup);
            const length = 0;
            const args = t.auctionInitializerArgs;
            const cfg = { ...args.auctionConfig, length };
            const err = auctionErr("INVALID_AUCTION_LENGTH");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.feeContract,
                        args.proofOfIdentity,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            )
                .to.be.revertedWithCustomError(f, err)
                .withArgs(length, DAY_SEC);
        });

        it("Should fail to deploy if an invalid NFT address is supplied", async function () {
            const t = await loadFixture(setup);
            const nft = ZERO_ADDRESS;
            const args = t.auctionInitializerArgs;
            const cfg = { ...args.auctionConfig, nft };
            const err = auctionErr("ZERO_ADDRESS");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.feeContract,
                        args.proofOfIdentity,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            ).to.be.revertedWithCustomError(f, err);
        });

        it("Should fail to deploy if an invalid beneficiary is supplied", async function () {
            const t = await loadFixture(setup);
            const beneficiary = ZERO_ADDRESS;
            const args = t.auctionInitializerArgs;
            const cfg = { ...args.auctionConfig, beneficiary };
            const err = auctionErr("ZERO_ADDRESS");

            const f = await ethers.getContractFactory("NFTAuction");

            await expect(
                upgrades.deployProxy(
                    f,
                    [
                        args.feeContract,
                        args.proofOfIdentity,
                        args.association,
                        args.developer,
                        args.feeCollector,
                        args.fnSigs,
                        args.fnFees,
                        cfg,
                    ],
                    { kind: "uups", initializer: "initialize" }
                )
            ).to.be.revertedWithCustomError(f, err);
        });

        it("Should not allow initialize to be called a second time", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract;
            const a = t.auctionInitializerArgs;
            const err = initialiazbleErr("ALREADY_INITIALIZED");

            await expect(
                c.initialize(
                    a.feeContract,
                    a.proofOfIdentity,
                    a.association,
                    a.developer,
                    a.feeCollector,
                    a.fnSigs,
                    a.fnFees,
                    a.auctionConfig
                )
            ).to.be.revertedWith(err);
        });
    });

    /* Starting an Auction
    ======================================== */
    describe("Starting an Auction", function () {
        it("Should only allow the dev to start an auction", async function () {
            const t = await loadFixture(setup);
            const c = t.auctionContract;
            const cDev = c.connect(t.developer);
            const err = accessControlErr("MISSING_ROLE");

            await expect(c.startAuction()).to.be.revertedWith(err);
            await expect(cDev.startAuction()).to.not.be.reverted;
        });

        it("Should revert if the auction has already been started", async function () {
            const t = await loadFixture(setup);
            const c = t.auctionContract.connect(t.developer);
            const err = auctionErr("ACTIVE");

            const txRes = await c.startAuction();
            txRes.wait();

            await expect(c.startAuction()).to.be.revertedWithCustomError(
                c,
                err
            );
        });

        it("Should transfer in the prize NFT", async function () {
            const t = await loadFixture(setup);
            const c = t.auctionContract.connect(t.developer);

            const txRes = await c.startAuction();
            txRes.wait();

            const bal = await t.nftContract.balanceOf(t.auctionContractAddress);
            expect(bal).to.equal(1);
        });

        it("Should emit an `AuctionStarted` event", async function () {
            const t = await loadFixture(setup);
            const c = t.auctionContract.connect(t.developer);
            const msg = "AuctionStarted";

            await expect(c.startAuction()).to.emit(c, msg);
        });

        it("Should revert if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.auctionContract;
            const cDev = t.auctionContract.connect(t.developer);
            const err = pausableErr("WHEN_NOT_PAUSED");

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            let txRes = await cDev.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(cDev.startAuction()).to.be.revertedWith(err);

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(cDev.startAuction()).to.not.be.reverted;
        });
    });

    /* Placing Bids
    ======================================== */
    describe("Placing Bids", function () {
        it("Should correctly place a bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cfg = t.auctionInitializerArgs.auctionConfig;
            const cDev = t.auctionContract.connect(t.developer);

            const cUser = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];

            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("15");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft to user
            await t.issueIdentity(args);

            // start the auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            const hasStarted = await t.auctionContract.hasStarted();
            expect(hasStarted).to.be.true;

            let highestBid = await t.auctionContract.getHighestBid();
            expect(highestBid).to.equal(cfg.startingBid);

            let highestBidder = await t.auctionContract.getHighestBidder();
            expect(highestBidder).to.equal(ZERO_ADDRESS);

            // place bid
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // test
            highestBid = await t.auctionContract.getHighestBid();
            expect(highestBid).to.equal(bid);

            highestBidder = await t.auctionContract.getHighestBidder();
            expect(highestBidder).to.equal(addr);
        });

        it("Should revert if the fee is insufficient", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft to user
            await t.issueIdentity(args);

            // start the auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            const hasStarted = await t.auctionContract.hasStarted();
            expect(hasStarted).to.be.true;

            // place bid with no value at all
            await expect(cUser.bid())
                .to.be.revertedWithCustomError(
                    cUser,
                    h1DevelopedErr("INSUFFICIENT_FUNDS")
                )
                .withArgs(0n, fee);

            // place bid with no value after fee
            await expect(
                cUser.bid({ value: fee })
            ).to.be.revertedWithCustomError(cUser, auctionErr("ZERO_VALUE"));
        });

        it("Should revert if the auction has not started", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("20");

            const err = auctionErr("NOT_STARTED");

            const fee = await c.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // sanity check
            const hasStarted = await t.auctionContract.hasStarted();
            expect(hasStarted).to.be.false;

            // test
            await expect(
                c.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the auction has finished", async function () {
            // vars
            const t = await loadFixture(setup);
            const len = t.auctionInitializerArgs.auctionConfig.length;

            const cDev = t.auctionContract.connect(t.developer);

            const cUser = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("100");

            const err = auctionErr("FINISHED");

            const fee = await cUser.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction and advance to end time
            const txRes = await cDev.startAuction();
            await txRes.wait();
            await time.increase(len + 1n);

            const hasFinished = await cUser.hasFinished();
            expect(hasFinished).to.be.true;

            // test
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should revert if the bid is too low", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);

            const cUser = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = t.auctionInitializerArgs.auctionConfig.startingBid / 2n;

            const fee = await cUser.getFnFeeAdj(fnSel);

            const err = auctionErr("BID_TOO_LOW");

            // issue id ndft
            await t.issueIdentity(args);

            // start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // test
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should revert if the new bid is the same as the current highest bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);

            const cUser = t.auctionContract.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = t.auctionInitializerArgs.auctionConfig.startingBid;

            const fee = await cUser.getFnFeeAdj(fnSel);

            const err = auctionErr("BID_TOO_LOW");

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // test
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should not allow the current highest bidder to outbid themselves / raise thier bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bidOne = parseH1("15");
            const bidTwo = parseH1("16");

            const err = auctionErr("ALREADY_HIGHEST");

            const fee = await cUser.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // first bid
            txRes = await cUser.bid({ value: bidOne + fee });
            await txRes.wait();

            // second bid
            await expect(
                cUser.bid({ value: bidTwo + fee })
            ).to.revertedWithCustomError(cUser, err);
        });

        it("Should refund the previous highest bid to the previous highest bidder upon a new successful bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUserOne = t.auctionContract.connect(t.accounts[0]);
            const cUserTwo = t.auctionContract.connect(t.accounts[1]);

            const addrOne = t.accountAddresses[0];
            const addrTwo = t.accountAddresses[1];

            const argsOne = newArgs(addrOne, "RETAIL");
            const argsTwo = newArgs(addrTwo, "RETAIL");

            const bidOne = parseH1("15");
            const bidTwo = parseH1("16");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nfts
            await t.issueIdentity(argsOne);
            await t.issueIdentity(argsTwo);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // first user bids
            txRes = await cUserOne.bid({ value: bidOne + fee });
            await txRes.wait();

            const userOneBalBefore = await getH1Balance(addrOne);

            // second user bids
            txRes = await cUserTwo.bid({ value: bidTwo + fee });
            await txRes.wait();

            const userOneBalAfter = await getH1Balance(addrOne);
            expect(userOneBalAfter).to.equal(userOneBalBefore + bidOne);
        });

        it("Should correctly update the highest bidder and highest bid", async function () {
            // vars
            const t = await loadFixture(setup);
            const startBid = t.auctionInitializerArgs.auctionConfig.startingBid;

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("81");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // initial
            const prevBidder = await cDev.getHighestBidder();
            const prevBid = await cDev.getHighestBid();

            expect(prevBidder).to.equal(ZERO_ADDRESS);
            expect(prevBid).to.equal(startBid);

            // user bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            const currBidder = await cDev.getHighestBidder();
            const currBid = await cDev.getHighestBid();

            expect(currBidder).to.equal(addr);
            expect(currBid).to.equal(bid);
        });

        it("Should revert if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.auctionContract;

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("81");

            const fee = await cDev.getFnFeeAdj(fnSel);
            const err = pausableErr("WHEN_NOT_PAUSED");

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            txRes = await cDev.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(cUser.bid({ value: bid + fee })).to.be.revertedWith(
                err
            );

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(cUser.bid({ value: bid + fee })).to.not.be.reverted;
        });

        it("Should emit a `BidPlaced` event upon successfully placing a bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("81");
            const msg = "BidPlaced";

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            const txRes = await cDev.startAuction();
            await txRes.wait();

            // should emit
            await expect(cUser.bid({ value: bid + fee }))
                .to.emit(cUser, msg)
                .withArgs(addr, bid);
        });

        it("Should not allow an account without an ID NFT to bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const fee = await cDev.getFnFeeAdj(fnSel);

            const bid = parseH1("19");
            const err = auctionErr("NO_ID");

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // no id nft
            await expect(
                cUser.bid({ value: bid + fee })
            ).to.be.revertedWithCustomError(cUser, err);
        });

        it("Should not allow an account that is suspended to bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const reason = "test-reason";
            const err = auctionErr("SUSPENDED");
            const bid = parseH1("22");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue nft id
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            txRes = await t.proofOfIdContract.suspendAccount(addr, reason);
            await txRes.wait();

            await expect(
                cUser.bid({ value: bid + fee })
            ).to.revertedWithCustomError(cUser, err);
        });

        it("Should not allow an account with an expired account type property to bid", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const exp = args.expiries[PROOF_OF_ID_ATTRIBUTES.USER_TYPE.id];
            const attr = PROOF_OF_ID_ATTRIBUTES.USER_TYPE.name;
            const err = auctionErr("ATTRIBUTE_EXPIRED");
            const bid = parseH1("22");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // advance time to point where the id nft has expired
            await time.increase(exp);

            // should not be able to bid
            await expect(cUser.bid({ value: bid + fee }))
                .to.be.revertedWithCustomError(cUser, err)
                .withArgs(attr, exp);
        });

        it("Should not allow an account of the wrong account type to bid", async function () {
            // vars
            const t = await loadFixture(setup);
            const auctionConfig: AuctionConfig = {
                ...t.auctionInitializerArgs.auctionConfig,
                kind: getAuctionKind("INSTITUTION"),
            };

            const nftArgs: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                auctionConfig,
            };

            // deploy auction for institutional users only
            const institutionOnly = await deployNFTAuction(
                nftArgs,
                t.association,
                0
            );

            const cDev = institutionOnly.connect(t.developer);

            const cUser = institutionOnly.connect(t.accounts[0]);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const err = auctionErr("USER_TYPE");
            const bid = parseH1("90");

            const fee = await cDev.getFnFeeAdj(fnSel);

            // approve new auction to transfer the nft on behalf of the dev
            let txRes = await t.nftContract
                .connect(t.developer)
                .approve(
                    await institutionOnly.getAddress(),
                    nftArgs.auctionConfig.nftID
                );
            await txRes.wait();

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            txRes = await cDev.startAuction();
            await txRes.wait();

            await expect(cUser.bid({ value: bid + fee }))
                .to.revertedWithCustomError(cUser, err)
                .withArgs(userType("RETAIL"), userType("INSTITUTION"));
        });
    });

    /* Ending an Auction
    ======================================== */
    describe("Ending an Auction", function () {
        it("Should revert if the auction has not started", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract;
            const err = auctionErr("NOT_STARTED");

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.auctionContract;
            const cDev = t.auctionContract.connect(t.developer);

            const len = t.auctionInitializerArgs.auctionConfig.length;

            const err = pausableErr("WHEN_NOT_PAUSED");

            // start the auction
            let txRes = await cDev.startAuction();
            txRes.wait();

            // advance time to end of auction
            await time.increase(len);

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            txRes = await cDev.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(cDev.endAuction()).to.be.revertedWith(err);

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(cDev.endAuction()).to.not.be.reverted;
        });

        it("Should revert if called before the auction length has been met", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);

            const err = auctionErr("ACTIVE");

            const txRes = await c.startAuction();
            txRes.wait();

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should revert if the auction is already finished", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);
            const len = t.auctionInitializerArgs.auctionConfig.length;
            const err = auctionErr("FINISHED");

            let txRes = await c.startAuction();
            txRes.wait();

            await time.increase(len);

            txRes = await c.endAuction();
            await txRes.wait();

            await expect(c.endAuction()).to.be.revertedWithCustomError(c, err);
        });

        it("Should transfer the prize NFT to the winner", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("22");

            const len = t.auctionInitializerArgs.auctionConfig.length;

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // user one bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // advance time to end of auction
            await time.increase(len);

            // tests
            const balBefore = await t.nftContract.balanceOf(addr);
            expect(balBefore).to.equal(0);

            txRes = await cUser.endAuction();
            await txRes.wait();

            const balAfter = await t.nftContract.balanceOf(addr);
            expect(balAfter).to.equal(1);
        });

        it("Should transfer the contract balance to the owner", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("22");

            const len = t.auctionInitializerArgs.auctionConfig.length;

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // advance time to end of auction
            await time.increase(len);

            // tests
            const balBefore = await getH1Balance(t.developerAddress);

            const contractBal = await getH1Balance(t.auctionContractAddress);
            expect(contractBal).to.equal(bid);

            txRes = await cUser.endAuction();
            await txRes.wait();

            const balAfter = await getH1Balance(t.developerAddress);
            const expected = balBefore + contractBal;

            expect(balAfter).to.equal(expected);
        });

        it("Should emit an `NFTSent` event when the NFT is transferred to the winner", async function () {
            // vars
            const t = await loadFixture(setup);

            const cDev = t.auctionContract.connect(t.developer);
            const cUser = t.auctionContract.connect(t.accounts[0]);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const bid = parseH1("22");
            const msg = "NFTSent";

            const len = t.auctionInitializerArgs.auctionConfig.length;

            const fee = await cDev.getFnFeeAdj(fnSel);

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await cDev.startAuction();
            await txRes.wait();

            // user one bids
            txRes = await cUser.bid({ value: bid + fee });
            await txRes.wait();

            // advance time to end of auction
            await time.increase(len);

            // test
            expect(cUser.endAuction).to.emit(cUser, msg).withArgs(addr, bid);
        });
    });

    /* Account Eligibility
    ======================================== */
    describe("Account Eligibility", function () {
        it("Should return false if the account does not have an ID NFT", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);
            const addr = t.accountAddresses[0];

            let txRes = await c.startAuction();
            await txRes.wait();

            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is suspended", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const reason = "test-reason";

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // suspend the user's account
            txRes = await t.proofOfIdContract.suspendAccount(addr, reason);
            await txRes.wait();

            // test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is not of the requisite user type", async function () {
            // vars
            const t = await loadFixture(setup);

            const auctionConfig: AuctionConfig = {
                ...t.auctionInitializerArgs.auctionConfig,
                kind: getAuctionKind("INSTITUTION"),
            };

            const nftArgs: NFTAuctionInitalizerArgs = {
                ...t.auctionInitializerArgs,
                auctionConfig,
            };

            // deploy auction for institutional users only
            const institutionOnly = await deployNFTAuction(
                nftArgs,
                t.association,
                0
            );

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");

            // issue id nft
            await t.issueIdentity(args);

            // approce new contract to transfer dev's nft
            let txRes = await t.nftContract
                .connect(t.developer)
                .approve(
                    await institutionOnly.getAddress(),
                    auctionConfig.nftID
                );
            await txRes.wait();

            // start auction
            txRes = await institutionOnly.connect(t.developer).startAuction();
            await txRes.wait();

            // test
            const isEligible = await institutionOnly.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return false if the account is has an expired user type attribute", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);

            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");
            const exp = args.expiries[PROOF_OF_ID_ATTRIBUTES.USER_TYPE.id];

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // advance time to point where id nft is expired
            await time.increase(exp);

            // test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.false;
        });

        it("Should return true if the account is eligible", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);
            const addr = t.accountAddresses[0];
            const args = newArgs(addr, "RETAIL");

            // issue id nft
            await t.issueIdentity(args);

            // start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // test
            const isEligible = await c.accountEligible(addr);
            expect(isEligible).to.be.true;
        });
    });

    /* Misc
    ======================================== */
    describe("Misc", function () {
        it("Should correctly get the in progress and finished state", async function () {
            // vars
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);
            const len = t.auctionInitializerArgs.auctionConfig.length;

            // start auction
            let txRes = await c.startAuction();
            await txRes.wait();

            // tests
            let inProgress = await c.inProgress();
            expect(inProgress).to.be.true;

            let hasFinished = await c.hasFinished();
            expect(hasFinished).to.be.false;

            await time.increase(len);

            txRes = await c.endAuction();
            await txRes.wait();

            inProgress = await c.inProgress();
            expect(inProgress).to.be.false;

            hasFinished = await c.hasFinished();
            expect(hasFinished).to.be.true;
        });

        it("Should correctly get the finish time", async function () {
            const t = await loadFixture(setup);

            const c = t.auctionContract.connect(t.developer);

            const len = t.auctionInitializerArgs.auctionConfig.length;

            let txRes = await c.startAuction();
            const txRec = await txRes.wait();

            const ts = await tsFromTxRec(txRec);

            const finishTime = await c.getFinishTime();
            const expected = BigInt(ts) + len;

            expect(finishTime).to.equal(expected);
        });
    });
});
