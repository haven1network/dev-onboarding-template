/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { SimpleStorage, FeeContract, FixedFeeOracle } from "@typechain";
import type { FeeInitalizerArgs } from "@utils/deploy/fee";
import type { SimpleStorageInitalizerArgs } from "@utils/deploy/simple-storage";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { deployFeeContract } from "@utils/deploy/fee";
import { deploySimpleStorage } from "@utils/deploy/simple-storage";
import { parseH1 } from "@utils/token";

/* TEST DEPLOY
================================================== */
/**
 * Creates a new instances of TestDeployment
 * @class   TestDeployment
 */
export class TestDeployment {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;

    private _association!: HardhatEthersSigner;
    private _associationAddress!: string;

    private _networkOperator!: HardhatEthersSigner;
    private _networkOperatorAddress!: string;

    private _deployer!: HardhatEthersSigner;
    private _deployerAddress!: string;

    private _developer!: HardhatEthersSigner;
    private _developerAddress!: string;

    private _accounts!: HardhatEthersSigner[];
    private _accountAddresses!: string[];

    private _feeContract!: FeeContract;
    private _feeInitializerArgs!: FeeInitalizerArgs;
    private _feeContractAddress!: string;

    private _simpleStorageContract!: SimpleStorage;
    private _simpleStorageContractAddress!: string;
    private _simpleStorageInitializerArgs!: SimpleStorageInitalizerArgs;

    private _feeOracleContract!: FixedFeeOracle;

    /* Init
    ======================================== */
    /**
     * Private constructor due to requirement for async init work.
     *
     * @constructor
     * @private
     */
    private constructor() {
        this._accounts = [];
        this._accountAddresses = [];

        this._isInitialized = false;
    }

    /**
     * Initializes `TestDeployment`. `isInitialized` will return false until
     * this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful
     *
     * @private
     * @async
     * @method  init
     * @returns {Promise<TestDeployment>} - Promise that resolves to the `TestDeployment`
     * @throws
     */
    private async init(): Promise<TestDeployment> {
        // Accounts
        const [assc, op, deployer, developer, ...rest] =
            await ethers.getSigners();

        this._association = assc;
        this._associationAddress = await assc.getAddress();

        this._networkOperator = op;
        this._networkOperatorAddress = await op.getAddress();

        this._deployer = deployer;
        this._deployerAddress = await deployer.getAddress();

        this._developer = developer;
        this._developerAddress = await developer.getAddress();

        for (let i = 0; i < rest.length; ++i) {
            this._accounts.push(rest[i]);
            this._accountAddresses.push(await rest[i].getAddress());
        }

        // Fee Oracle
        this._feeOracleContract = await this.deployFeeOracle(
            this._associationAddress,
            this._networkOperatorAddress,
            parseH1("1")
        );

        // Fee Contract
        this._feeInitializerArgs = {
            oracleAddress: await this._feeOracleContract.getAddress(),
            channels: [],
            weights: [],
            haven1Association: this._associationAddress,
            networkOperator: this._networkOperatorAddress,
            deployer: this._deployerAddress,
            minDevFee: parseH1("1"),
            maxDevFee: parseH1("3"),
            asscShare: parseH1("0.2"),
            gracePeriod: 600,
        };

        this._feeContract = await deployFeeContract(
            this._feeInitializerArgs,
            this._deployer,
            0
        );

        this._feeContractAddress = await this._feeContract.getAddress();

        // Simple Storage Contract

        // Note that these functions DO NOT exist on the Simple Storage
        // contract. They are added here simply to test functionality on init.
        // The correct functions are omitted so that the process of adding
        // function fees (while the responsibility of the Developed App
        // contract) can be demonstrated and tested in the `./simpleStorage.test.ts`
        // file.
        const fnSigs = ["increment()", "decrement()"];
        const fnFees = [parseH1("2"), parseH1("1")];

        this._simpleStorageInitializerArgs = {
            feeContract: this._feeContractAddress,
            association: this._associationAddress,
            developer: this._developerAddress,
            feeCollector: this._developerAddress,
            fnSigs,
            fnFees,
        };

        this._simpleStorageContract = await deploySimpleStorage(
            this._simpleStorageInitializerArgs,
            assc,
            0
        );

        this._simpleStorageContractAddress =
            await this._simpleStorageContract.getAddress();

        // Init
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `TestDeployment`, runs required
     * init and returns the instance.
     *
     * @public
     * @static
     * @async
     * @method  create
     * @returns {Promise<TestDeployment>} - Promise that resolves to `TestDeployment`
     */
    public static async create(): Promise<TestDeployment> {
        const instance = new TestDeployment();
        return await instance.init();
    }

    /* Test Contract Deployers
    ======================================== */
    /**
     * @method   deployFeeOracle
     * @async
     * @public
     * @param   {string}    assc
     * @param   {string}    op
     * @param   {bigint}    val
     * @returns {Promise<FixedFeeOracle>}
     */
    public async deployFeeOracle(
        assc: string,
        op: string,
        val: bigint
    ): Promise<FixedFeeOracle> {
        const f = await ethers.getContractFactory("FixedFeeOracle");
        const c = await f.deploy(assc, op, val);
        return await c.waitForDeployment();
    }

    /* Getters
    ======================================== */
    /**
     * @method      association
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get association(): HardhatEthersSigner {
        this.validateInitialized("association");
        return this._association;
    }

    /**
     * @method      associationAddress
     * @returns     {string}
     * @throws
     */
    public get associationAddress(): string {
        this.validateInitialized("associationAddress");
        return this._associationAddress;
    }

    /**
     * @method      networkOperator
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get networkOperator(): HardhatEthersSigner {
        this.validateInitialized("networkOperator");
        return this._networkOperator;
    }

    /**
     * @method      networkOperatorAddress
     * @returns     {string}
     * @throws
     */
    public get networkOperatorAddress(): string {
        this.validateInitialized("networkOperatorAddress");
        return this._networkOperatorAddress;
    }

    /**
     * @method      deployer
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get deployer(): HardhatEthersSigner {
        this.validateInitialized("deployer");
        return this._deployer;
    }

    /**
     * @method      deployerAddress
     * @returns     {string}
     * @throws
     */
    public get deployerAddress(): string {
        this.validateInitialized("deployerAddress");
        return this._deployerAddress;
    }

    /**
     * @method      developer
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get developer(): HardhatEthersSigner {
        this.validateInitialized("developer");
        return this._developer;
    }

    /**
     * @method      developerAddress
     * @returns     {string}
     * @throws
     */
    public get developerAddress(): string {
        this.validateInitialized("developerAddress");
        return this._developerAddress;
    }

    /**
     * @method      accounts
     * @returns     {HardhatEthersSigner[]}
     * @throws
     */
    public get accounts(): HardhatEthersSigner[] {
        this.validateInitialized("accounts");
        return this._accounts;
    }

    /**
     * @method      accountAddresses
     * @returns     {string[]}
     * @throws
     */
    public get accountAddresses(): string[] {
        this.validateInitialized("accountAddresses");
        return this._accountAddresses;
    }

    /**
     * @method      feeContract
     * @returns     {FeeContract}
     * @throws
     */
    public get feeContract(): FeeContract {
        this.validateInitialized("feeContract");
        return this._feeContract;
    }

    /**
     * @method      feeInitalizerArgs
     * @returns     {FeeInitalizerArgs}
     * @throws
     */
    public get feeInitalizerArgs(): FeeInitalizerArgs {
        this.validateInitialized("feeInitalizeArgs");
        return this._feeInitializerArgs;
    }

    /**
     * @method      feeContractAddress
     * @returns     {string}
     * @throws
     */
    public get feeContractAddress(): string {
        this.validateInitialized("feeContractAddress");
        return this._feeContractAddress;
    }

    /**
     * @method      feeOracleContract
     * @returns     {FixedFeeOracle}
     * @throws
     */
    public get feeOracleContract(): FixedFeeOracle {
        this.validateInitialized("feeOracleContract");
        return this._feeOracleContract;
    }

    /**
     * @method      simpleStorageContract
     * @returns     {SimpleStorage}
     * @throws
     */
    public get simpleStorageContract(): SimpleStorage {
        this.validateInitialized("simpleStorageContract");
        return this._simpleStorageContract;
    }

    /**
     * @method      simpleStorageContractAddress
     * @returns     {string}
     * @throws
     */
    public get simpleStorageContractAddress(): string {
        this.validateInitialized("simpleStorageContractAddress");
        return this._simpleStorageContractAddress;
    }

    /**
     * @method      simpleStorageInitializerArgs
     * @returns     {SimpleStorageInitalizerArgs}
     * @throws
     */
    public get simpleStorageInitializerArgs(): SimpleStorageInitalizerArgs {
        this.validateInitialized("simpleStorageArgs");
        return this._simpleStorageInitializerArgs;
    }

    /* Helpers
    ======================================== */
    /**
     *  Validates if the class instance has been initialized.
     *
     *  # Error
     *
     *  Will throw an error if the class instance has not been initialized.
     *
     *  @private
     *  @method     validateInitialized
     *  @param      {string}    method
     *  @throws
     */
    private validateInitialized(method: string): void {
        if (!this._isInitialized) {
            throw new Error(
                `Deployment not initialized. Call create() before accessing ${method}.`
            );
        }
    }
}
