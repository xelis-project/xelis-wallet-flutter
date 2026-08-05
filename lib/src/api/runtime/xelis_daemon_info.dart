import '../models/xelis_network.dart';

/// Stable snapshot returned by the daemon connected to a native wallet.
///
/// Integer values originating from Rust `u64` fields use [BigInt] so the same
/// contract remains lossless on native and Web targets.
final class XelisDaemonInfo {
  const XelisDaemonInfo({
    required this.height,
    required this.topoheight,
    required this.stableHeight,
    required this.stableTopoheight,
    required this.prunedTopoheight,
    required this.topBlockHash,
    required this.circulatingSupply,
    required this.burnedSupply,
    required this.emittedSupply,
    required this.maximumSupply,
    required this.difficulty,
    required this.blockTimeTarget,
    required this.averageBlockTime,
    required this.blockReward,
    required this.devReward,
    required this.minerReward,
    required this.mempoolSize,
    required this.version,
    required this.network,
    required this.blockVersion,
  });

  final BigInt height;
  final BigInt topoheight;
  final BigInt stableHeight;
  final BigInt stableTopoheight;
  final BigInt? prunedTopoheight;
  final String topBlockHash;
  final BigInt circulatingSupply;
  final BigInt burnedSupply;
  final BigInt emittedSupply;
  final BigInt maximumSupply;
  final String difficulty;
  final BigInt blockTimeTarget;
  final BigInt averageBlockTime;
  final BigInt blockReward;
  final BigInt devReward;
  final BigInt minerReward;
  final BigInt mempoolSize;
  final String version;
  final XelisNetwork network;
  final int blockVersion;
}
