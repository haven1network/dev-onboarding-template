/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type {
    AddressLike,
    BigNumberish,
    ContractTransactionReceipt,
} from "ethers";
import type {
    FeeContract,
    FixedFeeOracle,
    MockAccountManager,
    MockNFT,
    MockPermissionsInterface,
    NFTAuction,
    ProofOfIdentity,
} from "@typechain";
import type { ProofOfIdentityArgs } from "@utils/deploy/proof-of-identity";
import type { NFTAuctionInitalizerArgs } from "@utils/deploy/nft-auction";
import type { FeeInitalizerArgs } from "@utils/deploy/fee";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { deployProofOfIdentity } from "@utils/deploy/proof-of-identity";
import { deployNFTAuction, getAuctionKind } from "@utils/deploy/nft-auction";
import { deployFeeContract } from "@utils/deploy/fee";
import { parseH1 } from "@utils/token";
import { WEEK_SEC } from "../constants";

/* CONSTANTS, TYPES AND UTILS
================================================== */
export type IssueIdArgs = {
    account: AddressLike;
    primaryID: boolean;
    countryCode: string;
    proofOfLiveliness: boolean;
    userType: BigNumberish;
    expiries: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
    tokenURI: string;
};

export type UserTypeKey = keyof typeof USER_TYPE;
export type UserTypeVal = (typeof USER_TYPE)[keyof typeof USER_TYPE];

export const USER_TYPE = {
    RETAIL: 1,
    INSTITUTION: 2,
} as const;

/**
 * Returns the numeric value of a given user type.
 *
 * @function    userType
 * @param       {UserTypeKey}   key
 * @returns     {UserTypeVal}
 */
export function userType(key: UserTypeKey): UserTypeVal {
    return USER_TYPE[key];
}

type AuctionErrorKey = keyof typeof AUCTION_ERRORS;

const AUCTION_ERRORS = {
    ZERO_ADDRESS: "Auction__ZeroAddress",
    INVALID_AUCTION_KIND: "Auction__InvalidAuctionKind",
    INVALID_AUCTION_LENGTH: "Auction__InvalidAuctionLength",
    NOT_STARTED: "Auction__AuctionNotStarted",
    ACTIVE: "Auction__AuctionActive",
    FINISHED: "Auction__AuctionFinished",
    NO_ID: "Auction__NoIdentityNFT",
    SUSPENDED: "Auction__Suspended",
    ATTRIBUTE_EXPIRED: "Auction__AttributeExpired",
    USER_TYPE: "Auction__UserType",
    BID_TOO_LOW: "Auction__BidTooLow",
    ALREADY_HIGHEST: "Auction__AlreadyHighestBidder",
    TRANSFER_FAILER: "Auction__TransferFailed",
    ZERO_VALUE: "Auction__ZeroValue",
} as const satisfies Record<string, string>;

/**
 * Returns an error message from the `NFTAuction` contract.
 *
 * @function    auctionErr
 * @param       {AuctionErrorKey} err
 * @returns     {string}
 */
export function auctionErr(err: AuctionErrorKey): string {
    return AUCTION_ERRORS[err];
}

/* TEST DEPLOY
================================================== */
/**
 * Creates a new instances of NFTAuctionTest
 * @class   NFTAuctionTest
 */
export class NFTAuctionTest {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;

    private _association!: HardhatEthersSigner;
    private _associationAddress!: string;

    private _networkOperator!: HardhatEthersSigner;
    private _networkOperatorAddress!: string;

    private _developer!: HardhatEthersSigner;
    private _developerAddress!: string;

    private _accounts!: HardhatEthersSigner[];
    private _accountAddresses!: string[];

    private _proofOfIdContract!: ProofOfIdentity;
    private _proofOfIdContractAddress!: string;
    private _proofOfIdArgs!: ProofOfIdentityArgs;

    private _mockAccountManager!: MockAccountManager;
    private _mockAccountManagerAddress!: string;

    private _mockPermissionsInterface!: MockPermissionsInterface;
    private _mockPermissionsInterfaceAddress!: string;

    private _feeContract!: FeeContract;
    private _feeInitializerArgs!: FeeInitalizerArgs;
    private _feeContractAddress!: string;

    private _feeOracleContract!: FixedFeeOracle;

    private _nftContract!: MockNFT;
    private _nftContractAddress!: string;

    private _auctionContract!: NFTAuction;
    private _auctionContractAddress!: string;
    private _auctionInitializerArgs!: NFTAuctionInitalizerArgs;

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
     * Initializes `NFTAuctionTest`. `isInitialized` will return false until
     * this is run.
     *
     * Deploys an auction with a base config of:
     * -    Association as the deployer;
     * -    "ALL" (`3`) as the type;
     * -    `1` as the NFT ID;
     * -    `10` H1 as the starting bid; and
     * -    Seven (7) days as the auction length.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful
     *
     * @private
     * @async
     * @method  init
     * @returns {Promise<NFTAuctionTest>} - Promise that resolves to the `NFTAuctionTest`
     * @throws
     */
    private async init(): Promise<NFTAuctionTest> {
        // Accounts
        const [assc, op, developer, ...rest] = await ethers.getSigners();

        this._association = assc;
        this._associationAddress = await assc.getAddress();

        this._networkOperator = op;
        this._networkOperatorAddress = await op.getAddress();

        this._developer = developer;
        this._developerAddress = await developer.getAddress();

        for (let i = 0; i < rest.length; ++i) {
            this._accounts.push(rest[i]);
            this._accountAddresses.push(await rest[i].getAddress());
        }

        // Account Manager
        this._mockAccountManager = await this.deployMockAccountManager();
        this._mockAccountManagerAddress =
            await this._mockAccountManager.getAddress();

        // Permissions Interface
        this._mockPermissionsInterface =
            await this.deployMockPermissionsInterface(
                this._mockAccountManagerAddress
            );
        this._mockPermissionsInterfaceAddress =
            await this._mockPermissionsInterface.getAddress();

        // Proof of Identity
        this._proofOfIdArgs = {
            associationAddress: this._associationAddress,
            networkOperatorAddress: this._networkOperatorAddress,
            deployerAddress: this._associationAddress,
            permissionsInterfaceAddress: this._mockPermissionsInterfaceAddress,
            accountManagerAddress: this._mockAccountManagerAddress,
        };

        this._proofOfIdContract = await deployProofOfIdentity(
            this._proofOfIdArgs,
            assc,
            0
        );

        this._proofOfIdContractAddress =
            await this._proofOfIdContract.getAddress();

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
            deployer: this._associationAddress,
            minDevFee: parseH1("1"),
            maxDevFee: parseH1("3"),
            asscShare: parseH1("0.2"),
            gracePeriod: 600,
        };

        this._feeContract = await deployFeeContract(
            this._feeInitializerArgs,
            this._association,
            0
        );

        this._feeContractAddress = await this._feeContract.getAddress();

        // NFT
        this._nftContract = await this.deployNFT();
        this._nftContractAddress = await this._nftContract.getAddress();

        await this._nftContract.mint(this._developerAddress);

        // Auction
        const nftID = 1n;
        const fnSigs = ["bid()"];
        const fnFees = [parseH1("1")];

        this._auctionInitializerArgs = {
            feeContract: this._feeContractAddress,
            proofOfIdentity: this._proofOfIdContractAddress,
            association: this._associationAddress,
            developer: this._developerAddress,
            feeCollector: this._developerAddress,
            fnSigs,
            fnFees,
            auctionConfig: {
                kind: getAuctionKind("ALL"),
                length: BigInt(WEEK_SEC),
                startingBid: parseH1("10"),
                nft: this._nftContractAddress,
                nftID,
                beneficiary: this._developerAddress,
            },
        };

        this._auctionContract = await deployNFTAuction(
            this._auctionInitializerArgs,
            this._association,
            0
        );

        this._auctionContractAddress = await this._auctionContract.getAddress();

        // Approve the Auction contract to transfer the NFT from the dev
        const txRes = await this._nftContract
            .connect(this._developer)
            .approve(this._auctionContractAddress, nftID);

        await txRes.wait();

        const bal = await this._nftContract.balanceOf(this._developerAddress);

        if (bal != 1n) {
            throw new Error("Auction: NFT transfer unsuccessful");
        }

        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `NFTAuctionTest`, runs required
     * init and returns the instance.
     *
     * Deploys an auction with a base config of:
     * -    Association as the deployer;
     * -    "ALL" (`3`) as the type;
     * -    `1` as the NFT ID;
     * -    `10` H1 as the starting bid; and
     * -    Seven (7) days as the auction length.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful
     *
     * @public
     * @static
     * @async
     * @method  create
     * @returns {Promise<NFTAuctionTest>} - Promise that resolves to `NFTAuctionTest`
     * @throws
     */
    public static async create(): Promise<NFTAuctionTest> {
        const instance = new NFTAuctionTest();
        return await instance.init();
    }

    /* Test Contract Deployers
    ======================================== */
    /**
     * @method   deployMockAccountManager
     * @async
     * @public
     * @returns {Promise<MockAccountManager>}
     */
    public async deployMockAccountManager(): Promise<MockAccountManager> {
        const f = await ethers.getContractFactory("MockAccountManager");
        const c = await f.deploy();
        return await c.waitForDeployment();
    }
    /**
     * @method   deployMockPermissionsInterface
     * @async
     * @public
     * @returns {Promise<MockPermissionsInterface>}
     */
    public async deployMockPermissionsInterface(
        accountManager: string
    ): Promise<MockPermissionsInterface> {
        const f = await ethers.getContractFactory("MockPermissionsInterface");
        const c = await f.deploy(accountManager);
        return await c.waitForDeployment();
    }

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

    /**
     * Deploys the NFT contract with a max supply of `10_000`.
     *
     * @method   deployNFT
     * @async
     * @public
     * @returns {Promise<MockNFT>}
     * @throws
     */
    public async deployNFT(): Promise<MockNFT> {
        const f = await ethers.getContractFactory("MockNFT");
        const c = await f.deploy(10_000);
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
     * @method      proofOfIdContract
     * @returns     {ProofOfIdentity}
     * @throws
     */
    public get proofOfIdContract(): ProofOfIdentity {
        this.validateInitialized("proofOfIdContract");
        return this._proofOfIdContract;
    }

    /**
     * @method      proofOfIdContractAddress
     * @returns     {string}
     * @throws
     */
    public get proofOfIdContractAddress(): string {
        this.validateInitialized("proofOfIdContractAddress");
        return this._proofOfIdContractAddress;
    }

    /**
     * @method      mockAccountManager
     * @returns     {MockAccountManager}
     * @throws
     */
    public get mockAccountManager(): MockAccountManager {
        this.validateInitialized("mockAccountManager");
        return this._mockAccountManager;
    }

    /**
     * @method      mockAccountManager
     * @returns     {string}
     * @throws
     */
    public get mockAccountManagerAddress(): string {
        this.validateInitialized("mockAccountManagerAddress");
        return this._mockAccountManagerAddress;
    }

    /**
     * @method      mockPermissionsInterface
     * @returns     {MockPermissionsInterface}
     * @throws
     */
    public get mockPermissionsInterface(): MockPermissionsInterface {
        this.validateInitialized("mockPermissionsInterface");
        return this._mockPermissionsInterface;
    }

    /**
     * @method      mockPermissionsInterfaceAddress
     * @returns     {string}
     * @throws
     */
    public get mockPermissionsInterfaceAddress(): string {
        this.validateInitialized("mockPermissionsInterfaceAddress");
        return this._mockPermissionsInterfaceAddress;
    }

    /**
     * @method      proofOfIdArgs
     * @returns     {ProofOfIdentityArgs}
     * @throws
     */
    public get proofOfIdArgs(): ProofOfIdentityArgs {
        this.validateInitialized("proofOfIdArgs");
        return this._proofOfIdArgs;
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
     * @method      auctionContract
     * @returns     {MockNFT}
     * @throws
     */
    public get nftContract(): MockNFT {
        this.validateInitialized("nftContract");
        return this._nftContract;
    }

    /**
     * @method      nftContractAddress
     * @returns     {string}
     * @throws
     */
    public get nftContractAddress(): string {
        this.validateInitialized("nftContractAddress");
        return this._nftContractAddress;
    }

    /**
     * @method      auctionContract
     * @returns     {NFTAuction}
     * @throws
     */
    public get auctionContract(): NFTAuction {
        this.validateInitialized("auctionContract");
        return this._auctionContract;
    }

    /**
     * @method      auctionContractAddress
     * @returns     {string}
     * @throws
     */
    public get auctionContractAddress(): string {
        this.validateInitialized("auctionContractAddress");
        return this._auctionContractAddress;
    }

    /**
     * @method      auctionInitializerArgs
     * @returns     {NFTAuctionInitalizerArgs}
     * @throws
     */
    public get auctionInitializerArgs(): NFTAuctionInitalizerArgs {
        this.validateInitialized("simpleStorageArgs");
        return this._auctionInitializerArgs;
    }

    /* Helpers
    ======================================== */
    /**
     * Issues an ID and returns the transaction reciept.
     *
     * @async
     * @func    issueIdentity
     * @param   {IssueIdArgs}           args
     * @param   {HardhatEthersSigner}   [signer]
     * @returns {ContractTransactionReceipt | null}
     */
    public async issueIdentity(
        args: IssueIdArgs,
        signer?: HardhatEthersSigner
    ): Promise<ContractTransactionReceipt | null> {
        this.validateInitialized("issueIdentity");

        const c = signer
            ? this._proofOfIdContract.connect(signer)
            : this._proofOfIdContract;

        const txRes = await c.issueIdentity(
            args.account,
            args.primaryID,
            args.countryCode,
            args.proofOfLiveliness,
            args.userType,
            args.expiries,
            args.tokenURI
        );

        return await txRes.wait();
    }

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
