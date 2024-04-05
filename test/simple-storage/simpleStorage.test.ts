/* IMPORT NODE MODULES
================================================== */
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { TestDeployment } from "./setup";
import {
    ZERO_ADDRESS,
    accessControlErr,
    h1DevelopedErr,
    initialiazbleErr,
    pausableErr,
} from "../constants";
import { parseH1 } from "@utils/token";
import { fnSelector } from "@utils/fnSelector";

/* CONSTANTS
================================================== */
const dir = {
    DECR: 0,
    INCR: 1,
} as const;

const evt = "Count";

/* TESTS
================================================== */
describe("H1 Developed Application - Simple Storage Example", function () {
    async function setup() {
        return await TestDeployment.create();
    }

    /* Deployment and Init
    ========================================*/
    describe("Deployment and Initialization", function () {
        it("Should have a deployment address", async function () {
            const t = await loadFixture(setup);
            const addr = t.simpleStorageContractAddress;
            expect(addr).to.have.length(42);
            expect(addr).to.not.equal(ZERO_ADDRESS);
        });

        it("Should not allow initialize to be called a second time", async function () {
            const t = await loadFixture(setup);

            const c = t.simpleStorageContract;
            const a = t.simpleStorageInitializerArgs;
            const err = initialiazbleErr("ALREADY_INITIALIZED");

            await expect(
                c.initialize(
                    a.feeContract,
                    a.association,
                    a.developer,
                    a.feeCollector,
                    a.fnSigs,
                    a.fnFees
                )
            ).to.be.revertedWith(err);
        });
    });

    /* Increment Count
    ========================================*/
    describe("Increment Count", function () {
        it("Should correctly increment the count", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const d = c.connect(t.developer);

            const fnSig = "incrementCount()";
            const fee = parseH1("2.25");
            const fnSel = fnSelector(fnSig);

            const err = h1DevelopedErr("INSUFFICIENT_FUNDS");

            // incr count before fee is added
            let count = await c.count();
            expect(count).to.equal(0n);

            let txRes = await c.incrementCount();
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            // set a fee on incr count
            txRes = await d.proposeFee(fnSig, fee);
            await txRes.wait();

            // approve fee
            txRes = await c.approveAllFees();
            await txRes.wait();

            // incr the count
            const feeAdj = await c.getFnFeeAdj(fnSel);

            txRes = await c.incrementCount({ value: feeAdj });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(2n);

            // sanity check on incr with no fee
            await expect(c.incrementCount())
                .to.be.revertedWithCustomError(c, err)
                .withArgs(0n, feeAdj);
        });

        it("Should emit a Count event", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const d = c.connect(t.developer);
            const addr = t.associationAddress;

            const fnSig = "incrementCount()";
            const fee = parseH1("2.25");

            // set a fee on incr count
            let txRes = await d.proposeFee(fnSig, fee);
            await txRes.wait();

            // approve fee
            txRes = await c.approveAllFees();
            await txRes.wait();

            // test event emit
            await expect(c.incrementCount({ value: fee }))
                .to.emit(c, evt)
                .withArgs(addr, dir.INCR, 1n, fee);
        });

        it("Should revert if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const err = pausableErr("WHEN_NOT_PAUSED");

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            let txRes = await c.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(c.incrementCount()).to.be.revertedWith(err);

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(c.incrementCount()).to.not.be.reverted;
        });
    });

    /* Decrement Count
    ========================================*/
    describe("Decrement Count", function () {
        it("Should correctly decrement the count", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const d = c.connect(t.developer);

            const fnSig = "decrementCount()";
            const fee = parseH1("1.75");
            const fnSel = fnSelector(fnSig);

            const err = h1DevelopedErr("INSUFFICIENT_FUNDS");

            // decr count before fee is added
            let count = await c.count();
            expect(count).to.equal(0n);

            let txRes = await c.incrementCount();
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            txRes = await c.decrementCount();
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);

            // set a fee on decr count
            txRes = await d.proposeFee(fnSig, fee);
            await txRes.wait();

            // approve fee
            txRes = await c.approveAllFees();
            await txRes.wait();

            // decr the count
            const feeAdj = await c.getFnFeeAdj(fnSel);

            txRes = await c.incrementCount({ value: feeAdj });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            txRes = await c.decrementCount({ value: feeAdj });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);

            // sanity check on decr with no fee
            await expect(c.decrementCount())
                .to.be.revertedWithCustomError(c, err)
                .withArgs(0n, feeAdj);
        });

        it("Should return early if the count is already zero", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;

            // state checks
            let count = await c.count();
            expect(count).to.equal(0n);

            // should not revert and count remains zero
            const txRes = await c.decrementCount();
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);
        });

        it("Should emit a Count event", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const d = c.connect(t.developer);
            const addr = t.associationAddress;

            const fnSig = "decrementCount()";
            const fee = parseH1("1.5");

            // increment first
            let txRes = await c.incrementCount();
            await txRes.wait();

            const count = await c.count();
            expect(count).to.equal(1n);

            // set a fee on decr count
            txRes = await d.proposeFee(fnSig, fee);
            await txRes.wait();

            // approve fee
            txRes = await c.approveAllFees();

            // test event emit
            await expect(c.decrementCount({ value: fee }))
                .to.emit(c, evt)
                .withArgs(addr, dir.DECR, 0n, fee);

            await txRes.wait();
        });

        it("Should revert if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const err = pausableErr("WHEN_NOT_PAUSED");

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            let txRes = await c.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(c.decrementCount()).to.be.revertedWith(err);

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(c.decrementCount()).to.not.be.reverted;
        });
    });

    /* Reset Count
    ========================================*/
    describe("Reset Count", function () {
        it("Should correctly reset the count", async function () {
            // vars
            const t = await loadFixture(setup);
            const d = t.simpleStorageContract.connect(t.developer);
            const rounds = 5;

            // set initial count
            let count = await d.count();
            expect(count).to.equal(0n);

            for (let i = 0; i < rounds; ++i) {
                const txRes = await d.incrementCount();
                await txRes.wait();
            }

            count = await d.count();
            expect(count).to.equal(rounds);

            // test reset
            const txRes = await d.resetCount();
            await txRes.wait();

            count = await d.count();
            expect(count).to.equal(0n);
        });

        it("Should only allow an account with the role DEFAULT_DEV_ROLE to reset the count ", async function () {
            // vars
            const t = await loadFixture(setup);
            const d = t.simpleStorageContract.connect(t.developer);
            const u = d.connect(t.accounts[0]);
            const err = accessControlErr("MISSING_ROLE");

            // case - no role
            await expect(u.resetCount()).to.be.revertedWith(err);

            // case - has role
            await expect(d.resetCount()).to.not.be.reverted;
        });

        it("Should fail to reset the count if the contract is paused", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const cDev = t.simpleStorageContract.connect(t.developer);
            const err = pausableErr("WHEN_NOT_PAUSED");

            // state check
            let isPaused = await c.paused();
            expect(isPaused).to.be.false;

            // pause the contract
            let txRes = await c.pause();
            await txRes.wait();

            // case - contract is paused
            await expect(cDev.resetCount()).to.be.revertedWith(err);

            // case - contract is not paused
            txRes = await c.unpause();
            await txRes.wait();
            await expect(cDev.incrementCount()).to.not.be.reverted;
        });
    });

    /* Get Count
    ========================================*/
    describe("Get Count", function () {
        it("Should correctly get the count", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorageContract;
            const rounds = 10;

            // set initial count
            let count = await c.count();
            expect(count).to.equal(0n);

            for (let i = 0; i < rounds; ++i) {
                const txRes = await c.incrementCount();
                await txRes.wait();
                count = await c.count();
                expect(count).to.equal(i + 1);
            }

            count = await c.count();
            expect(count).to.equal(rounds);
        });
    });
});
