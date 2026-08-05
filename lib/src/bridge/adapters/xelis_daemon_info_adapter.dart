import '../../api/runtime/xelis_daemon_info.dart';
import '../../generated/rust_bridge/api/models/runtime_dtos.dart' as generated;
import 'xelis_network_adapter.dart';

XelisDaemonInfo xelisDaemonInfoFromGenerated(generated.WalletDaemonInfo info) =>
    XelisDaemonInfo(
      height: info.height,
      topoheight: info.topoheight,
      stableHeight: info.stableHeight,
      stableTopoheight: info.stableTopoheight,
      prunedTopoheight: info.prunedTopoheight,
      topBlockHash: info.topBlockHash,
      circulatingSupply: info.circulatingSupply,
      burnedSupply: info.burnedSupply,
      emittedSupply: info.emittedSupply,
      maximumSupply: info.maximumSupply,
      difficulty: info.difficulty,
      blockTimeTarget: info.blockTimeTarget,
      averageBlockTime: info.averageBlockTime,
      blockReward: info.blockReward,
      devReward: info.devReward,
      minerReward: info.minerReward,
      mempoolSize: info.mempoolSize,
      version: info.version,
      network: xelisNetworkFromGenerated(info.network),
      blockVersion: info.blockVersion,
    );
