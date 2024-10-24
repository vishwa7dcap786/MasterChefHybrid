MasterChefHybrid

    MasterChefHybrid is a smart contract that combines the functionalities of both MasterChef V1 and V2 into a single contract. This contract manages staking pools, rewards distribution, and liquidity mining, while also having the minting rights for the SUSHI token. It's designed to behave like MasterChef V2 but with added flexibility from V1, and introduces new features like support for rewarder contracts and LP token migration.

Features

    * SUSHI Minting Rights: The contract has sole authority to mint new SUSHI tokens.
    * Staking Pools: Users can stake liquidity provider (LP) tokens to earn SUSHI rewards.
    * Pool Management: Owners can add new pools, update existing ones, and manage LP tokens.
    * Reward Allocation: Automatically allocates SUSHI tokens as rewards based on staked amounts.
    * Bonus Multiplier: Early SUSHI stakers can benefit from a bonus reward multiplier.
    * Rewarder Contract Support: Integrates with rewarder contracts for customizable reward distribution.
    * LP Token Migration: Provides an easy mechanism to migrate LP tokens through the IMigratorChef interface.

Smart Contract Breakdown

Core Contracts and Interfaces

    * IRewarder: Manages additional token rewards distribution.
    * IMigratorChef: Handles LP token migration.
    * IMasterChef: The parent interface, providing pool and user information.
    * sushiToken: Implements SUSHI minting and authorization functionalities.
Structs
    * UserInfo: Stores user-specific information like staked amount and reward debt.
    * PoolInfo: Contains pool-specific details like allocation points, reward information, and LP token address.
Key Events
    * Deposit: Emitted when a user deposits LP tokens.
    * Withdraw: Emitted when a user withdraws LP tokens.
    * Harvest: Emitted when a user claims SUSHI rewards.
    * EmergencyWithdraw: Allows users to withdraw staked tokens without claiming rewards.
    * LogPoolAddition: Logs when a new pool is added by the owner.
    * LogSetPool: Logs updates to a pool's allocation points and rewarder contract.
    * LogUpdatePool: Logs when a pool's reward variables are updated.

Setup and Usage

Constructor
    The contract is initialized with the following parameters:

solidity
Copy code
constructor(
    sushiToken _sushi,
    address _devaddr,
    uint256 _sushiPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock
)
* _sushi: Address of the SUSHI token contract.
* _devaddr: Developer's address to receive a portion of the minted rewards.
* _sushiPerBlock: The amount of SUSHI minted per block.
* _startBlock: Block number at which SUSHI mining starts.
* _bonusEndBlock: Block number at which the bonus multiplier ends.

Core Functions
    * add(): Add a new LP token pool.
    * set(): Update pool allocation points or rewarder.
    * deposit(): Deposit LP tokens into the pool.
    * withdraw(): Withdraw LP tokens from the pool.
    * harvest(): Claim SUSHI rewards.
    * migrate(): Migrate LP tokens using the migrator contract.

Pool Management
    * massUpdatePools(): Update reward variables for all pools in a single transaction.
    * updatePool(): Update a specific pool’s reward variables.
    * pendingSushi(): Check the pending SUSHI reward for a user in a specific pool.

Emergency Functions
    * emergencyWithdraw(): Allows users to withdraw their LP tokens without harvesting rewards in case of emergencies.

Installation
Clone the repository:

bash
Copy code
git clone https://github.com/your-username/MasterChefHybrid.git


Install the necessary dependencies:

bash
Copy code
npm install
Compile the contract:

bash
Copy code
npx hardhat compile
Deploy the contract:

bash
Copy code
npx hardhat run scripts/deploy.js
Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

License
MIT

