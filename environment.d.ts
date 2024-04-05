declare global {
    namespace NodeJS {
        interface ProcessEnv {
            // Testnet
            TESTNET_CHAIN_ID?: string;
            HAVEN_TESTNET_RPC?: string;

            TESTNET_EXPLORER?: string;
            TESTNET_EXPLORER_API?: string;
            TESTNET_EXPLORER_API_KEY?: string;

            TESTNET_DEPLOYER?: string;
            TESTNET_ASSOCIATION_ADDRESS?: string;
            TESTNET_OPERATOR_ADDRESS?: string;
            TESTNET_DEV_ADDRESS?: string;
            TESTNET_FEE_CONTRACT?: string;
            TESTNET_POI_CONTRACT?: string;
        }
    }
}

export {};
