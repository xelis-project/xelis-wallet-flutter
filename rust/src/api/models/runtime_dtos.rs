use xelis_common::{api::daemon::GetInfoResult, network::Network};

/// Bridge-owned snapshot of the daemon information used by wallet consumers.
///
/// The exhaustive destructuring in `From<GetInfoResult>` intentionally makes
/// upstream RPC contract drift a compile-time failure when the locked XELIS
/// dependencies are updated.
#[derive(Clone, Debug)]
pub struct WalletDaemonInfo {
    pub height: u64,
    pub topoheight: u64,
    pub stable_height: u64,
    pub stable_topoheight: u64,
    pub pruned_topoheight: Option<u64>,
    pub top_block_hash: String,
    pub circulating_supply: u64,
    pub burned_supply: u64,
    pub emitted_supply: u64,
    pub maximum_supply: u64,
    pub difficulty: String,
    pub block_time_target: u64,
    pub average_block_time: u64,
    pub block_reward: u64,
    pub dev_reward: u64,
    pub miner_reward: u64,
    pub mempool_size: u64,
    pub version: String,
    pub network: Network,
    pub block_version: u8,
}

impl From<GetInfoResult> for WalletDaemonInfo {
    fn from(info: GetInfoResult) -> Self {
        let GetInfoResult {
            height,
            topoheight,
            stableheight,
            stable_topoheight,
            pruned_topoheight,
            top_block_hash,
            circulating_supply,
            burned_supply,
            emitted_supply,
            maximum_supply,
            difficulty,
            block_time_target,
            average_block_time,
            block_reward,
            dev_reward,
            miner_reward,
            mempool_size,
            version,
            network,
            block_version,
        } = info;

        Self {
            height,
            topoheight,
            stable_height: stableheight,
            stable_topoheight,
            pruned_topoheight,
            top_block_hash: top_block_hash.to_string(),
            circulating_supply,
            burned_supply,
            emitted_supply,
            maximum_supply,
            difficulty: difficulty.to_string(),
            block_time_target,
            average_block_time,
            block_reward,
            dev_reward,
            miner_reward,
            mempool_size: mempool_size as u64,
            version,
            network,
            block_version: block_version as u8,
        }
    }
}
