# Solidity-Project-Foundry

# 项目概述
本仓库 Solidity-Project-Foundry 是一个基于 Foundry 工具集的以太坊智能合约项目集合，包含了多个子项目，如 lottery、fund 和 defi-stablecoin。Foundry 是一个用 Rust 编写的快速、可移植且模块化的以太坊应用开发工具包，提供了一系列强大的工具，包括 Forge（测试框架）、Cast（与 EVM 智能合约交互的工具）、Anvil（本地以太坊节点）和 Chisel（Solidity REPL）。

# 子项目介绍
## lottery
功能：实现了一个抽奖相关的智能合约。

## fund
功能：实现了一个资金相关的智能合约。
使用方法：
构建项目：
shell
$ forge build
运行测试：
shell
$ forge test
格式化代码：
shell
$ forge fmt
启动本地节点：
shell
$ anvil
生成 Gas 快照：
shell
$ forge snapshot
使用 Cast 工具：
shell
$ cast <subcommand>
查看帮助信息：
shell
$ forge --help
$ anvil --help
$ cast --help

## defi-stablecoin

功能：实现了一个去中心化稳定币的智能合约。
相对稳定性：锚定或挂钩 1.00 美元，使用 Chainlink 价格预言机，设置了交换 ETH 与 BTC 为美元的功能。
人们只能用足够的抵押品（通过代码实现）铸造稳定币，抵押品为外部加密货币（wETH、wBTC）。
使用方法：
项目的构建、测试和格式化等操作与其他子项目类似，可参考上述 lottery 和 fund 的使用方法。
项目配置
.gitignore
各个子项目的 .gitignore 文件配置基本相同，主要忽略了编译器生成的文件（如 cache/、out/）、开发广播日志（部分特定环境日志）、文档目录（docs/）和环境变量文件（.env）。
foundry.toml
不同子项目的 foundry.toml 文件有一些细微差异，但都包含了基本的配置信息，如源文件目录（src）、输出目录（out）、依赖库目录（libs）等。部分项目还配置了 FFI 支持、文件系统权限等。