# Lecture

在[登链社区](https://learnblockchain.cn/)和 [rebase 社区](https://github.com/rebase-network)分享 SLOADS


今天和大家分享我们在 ETHBeijing Hackathon 上做的工作。

因为 EVM 存在一些限制，所以 Foundry 在本地测试的时候，有作弊码来突破这些限制。简单的说我们就是新增了一组作弊码，来获取某个智能合约的存储 Slot。

要介绍 EVM 的限制，需要先介绍 EVM 的存储布局等背景知识。
## EVM 存储布局

这个图片的来源我放后面 reference 了，它有 100 多页，讲得挺细致的，推荐。

![](img/Blockchain.png)

这里是我们熟悉的区块链，一组新的交易构造成区块，然后一个区块接一个区块，就组成了区块链。

以太坊除了区块链之外，还有世界状态，World state，黄皮书里面把以太坊描述成基于交易的状态机。通过区块里面的交易，来改变以太坊的世界状态。

![](img/statechain.png)


那么这个世界状态里面有什么, 这个世界状态是有很多 Account 对象组成

![](img/account.png)


Account 的包含 nonce, balance, storage, code 这四个信息。其中对于 EOA 账号，就是用户用私钥控制的账号，就只有 nonce 和 balance 有用，然后对于 合约账号，还有 storage 和 code。其中 storage 就是用于永久存储合约里面的状态变量。
![](img/two_account.png)

Account 里面的 storage 是这样的，key 就是 storage slot，然后 value 就是存储对应的值了，key 和 value 都是 256 bit，存储空间可以存储 $2^{256}$ 个条目。一般来讲，这个空间肯定够用的。

![](img/storage.png)

Solidity 里面我们可以申明很多状态变量，那么它们是怎么和这个唯一的存储空间对应上的？

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title RecordMapping
contract Storage {
    int256 value;
    mapping(address => int256) map;
    mapping(int256 => mapping(int256 => int256)) doubleMap;
    uint256[] public arr;

    function setMap(address addr, int256 val) public {
        map[addr] = val;
    }

    function setDoubleMap(int256 i, int256 j) public {
        doubleMap[i][j] = i * j;
    }

    function pushArray(uint256 i) public {
        arr.push(i);
    }

    function getArrayLength() public view returns (uint256) {
        return arr.length;
    }
}
```

Solidity 文档里面有关于[存储布局的描述](https://docs.soliditylang.org/en/develop/internals/layout_in_storage.html):

![](img/storage_layout.png)

比如上面这个合约，里面有 value，map，doubleMap，arr 四个状态变量，根据描述，它们的存储占用是：

```sh
$ forge inspect ./src/Storage.sol:Storage storage --pretty            
| Name      | Type                                         | Slot | Offset | Bytes | Contract                |
| --------- | -------------------------------------------- | ---- | ------ | ----- | ----------------------- |
| value     | int256                                       | 0    | 0      | 32    | src/Storage.sol:Storage |
| map       | mapping(address => int256)                   | 1    | 0      | 32    | src/Storage.sol:Storage |
| doubleMap | mapping(int256 => mapping(int256 => int256)) | 2    | 0      | 32    | src/Storage.sol:Storage |
| arr       | struct Storage.Struct[]                      | 3    | 0      | 32    | src/Storage.sol:Storage |
```

如果往 map, doubleMap 以及 arr 里面添加元素的话，那么布局大概是怎样的呢？这个需要后面我们结合 demo 来具体展示


## Foundry 作弊码原理

Foundry 里面直接使用 Solidity 写测试，很方便，而且这也符合编程习惯，就是你用其他语言的时候，你写测试也是用和 src code 同一个语言写测试嘛。

但是标准的 solidity 功能有限，甚至无法完成基本的测试。所以我们需要扩展一些额外的功能来满足测试的需要，这是 Cheatcode 的来源。

Foundry book 里面有对 [Cheatcodes](https://book.getfoundry.sh/forge/cheatcodes) 的具体描述，就是能够赋予开发者额外的能力，比如修改状态等。

Foundry 里面的 cheatcode 形式上都是用 `vm.function()` 去调用，我们可以去看一下 forge-std, 首先它这些都是 interface，都没有实现的，然后在 Base.sol 里面，vm 指定一个合约地址，它是这样生成的：
```solidity
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
```

因此这个地址里面也没有合约代码。


Foundry 是这样做的，在执行的时候, evm 会先[检查调用的地址](https://github.com/foundry-rs/foundry/blob/master/evm/src/executor/inspector/cheatcodes/mod.rs#L537-L542)是不是我们指定的 vm 地址，如果是的，我们就不去加载里面的 bytecode，以及那个合约的 storage 等。而是直接执行 [Rust 实现的对应的功能](https://github.com/foundry-rs/foundry/blob/master/evm/src/executor/inspector/cheatcodes/env.rs#L217)。所以整的来说就是通过 EVM 底层监听并拦截对特定地址的调用，然后特殊处理。

现在有很多兼容 EVM 的链，它们经常增加一些“系统合约”，其实原理是一样的。

## SLOADS 的工作

某个合约，经过一些交易之后它的 Storage 布局是怎样的？具体的例子就是某个 token 合约，holder 有哪些人，有哪些人 approve 别人使用他们的 token，某个人 approve 哪些人使用 token？

https://github.com/foundry-rs/foundry/pull/4710/files

## Demo


storage layout：
| slot               | var                      | value          |
| ------------------ | ------------------------ | -------------- |
| slot 0             | value                    | 0              |
| slot 1             | map                      | 0              |
| slot 2             | doubleMap                | 0              |
| slot 3             | arr                      | arr.length     |
| ...                |
| slot keccak(key~1) | map(key)                 | map(key)       |
| ...                |
| slot keccak(3) + 0 | arr[0].val1              | 50 years       |
| slot keccak(3) + 1 | arr[0].val2              | 2              |
| slot keccak(0) + 3 | queue[1].unlockTimestamp | 2^256 - 1 days |
| slot keccak(0) + 4 | queue[1].amount          | 3              |
| slot keccak(0) + 5 | queue[1].unlockTimestamp | 0              |
| ...                |



## reference
* https://takenobu-hs.github.io/downloads/ethereum_evm_illustrated.pdf