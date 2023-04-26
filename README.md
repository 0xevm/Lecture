# Lecture

**Install Modified Forge**

```sh
$ git clone https://github.com/0xevm/foundry.git

$ cd foundry
  
$ git checkout beijing-eth

$ cargo build --release -p foundry-cli --bin forge

# !! update the PATH to your foundry build release path
$ export PATH="/Users/flyq/workspace/github/0xevm/foundry/target/release:$PATH"

# confirm the forge is the modified forge
$ which forge
/Users/flyq/workspace/github/0xevm/foundry/target/release/forge
```

**Testing**

```sh
$ forge install 0xevm/forge-std-new

$ forge test -vvv
```