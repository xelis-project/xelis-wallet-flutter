import '../../api/models/xelis_network.dart';
import '../../generated/rust_bridge/api/models/network.dart' as generated;

generated.Network generatedNetworkFromXelis(XelisNetwork network) =>
    switch (network) {
      XelisNetwork.mainnet => generated.Network.mainnet,
      XelisNetwork.testnet => generated.Network.testnet,
      XelisNetwork.devnet => generated.Network.devnet,
      XelisNetwork.stagenet => generated.Network.stagenet,
    };

XelisNetwork xelisNetworkFromGenerated(generated.Network network) =>
    switch (network) {
      generated.Network.mainnet => XelisNetwork.mainnet,
      generated.Network.testnet => XelisNetwork.testnet,
      generated.Network.devnet => XelisNetwork.devnet,
      generated.Network.stagenet => XelisNetwork.stagenet,
    };
