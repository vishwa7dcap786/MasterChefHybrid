// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SushiToken} from "./SushiToken.sol";
import {MasterChefHybrid,IMasterChef,IMigratorChef,IRewarder,sushiToken} from "../src/MasterChefHybrid.sol";
import {IERC20} from "../src/IERC20.sol";
import {Migrator} from "./Migrator.sol";
import {LpToken} from "./LpToken.sol";


contract CounterTest is Test {
    SushiToken public sushi;
    MasterChefHybrid public masterChefV;
    LpToken public lp;
    address public USER = makeAddr("user");
    function setUp() public {
        //MasterChefV1 setUp
        sushi = new SushiToken();
        lp = new LpToken("Lp","lp");
        masterChefV = new MasterChefHybrid(sushiToken(address(sushi)),USER,100 ether,block.number,0);
        sushi.setAuthorizedMinter(address(masterChefV),true);
        masterChefV.add(1000,IERC20(address(lp)),IRewarder(address(0)));

    }
    

    function testMigrate() public {
        setUpMasterChefV(5 ether, 100, 0);
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        lpM.mint(address(migrator),5 ether);
        masterChefV.setMigrator(IMigratorChef(address(migrator)));
        masterChefV.migrate(0);
        assertEq(lpM.balanceOf(address(masterChefV)),5 ether);

    }

    function testMigratorToken() public {
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        address token = address(migrator.tokenToMigrate());
        assertEq(token, address(lpM));
    }

    


    function testSushiPerBlock() public {
        uint256 sushiPerBlock = masterChefV.sushiPerBlock();
        assertEq(sushiPerBlock, 100 ether);
    }

    function testSet() public{
        masterChefV.set(0,1000,IRewarder(address(0)),false);
        (uint128 accSushiPerShare,uint64 lastRewardBlock,uint64 allocPoint) = (masterChefV.poolInfo(0));
        assertEq(masterChefV.totalAllocPoint(),1000);
        assertEq(allocPoint,1000);
    }

    function testDeposit() public {
        setUpMasterChefV(5 ether, 100, 0);
        (uint256 amount, int256 rewardDept) = masterChefV.userInfo(0,address(this));
        assertEq(amount,5 ether);
        assertEq(rewardDept,0);
    }


    function testWithdraw() public {
        setUpMasterChefV(5 ether, 100, 0);
        masterChefV.withdraw(0, 3 ether, address(this));
        uint256 amountreceived = lp.balanceOf(address(this));
        uint256 rewards = masterChefV.pendingSushi(0,address(this));
        (uint256 amount, int256 rewardDept) = masterChefV.userInfo(0,address(this));       
        assertEq(rewards,9900 ether);
        assertEq(amountreceived,3 ether);
        assertEq(amount, 2 ether);
        assertEq(rewardDept,-5940000000000000000000);

    }

    function testHarvest() public {
        setUpMasterChefV(5 ether, 100, 0);
        masterChefV.withdraw(0, 3 ether, address(this));
        masterChefV.harvest(0,address(this));
        uint256 rewardsReceived = sushi.balanceOf(address(this));
        assertEq(rewardsReceived, 9900 ether);
    }

    function testWithdrawAndHarvest() public {
        setUpMasterChefV(5 ether, 100, 0);
        masterChefV.withdrawAndHarvest(0, 3 ether, address(this));
        uint256 rewardsReceived = sushi.balanceOf(address(this));
        uint256 amountreceived = lp.balanceOf(address(this));
        assertEq(rewardsReceived, 9900 ether);
        assertEq(amountreceived, 3 ether);
    }

    function testpendingSushi() public {

        setUpMasterChefV(5 ether, 100, 0);
        uint256 rewardsOfThis = masterChefV.pendingSushi(0,address(this));
        assertEq(rewardsOfThis,9900 ether);
    }

    function testupdatePool() public {
        setUpMasterChefV(5 ether, 100, 0);
        masterChefV.updatePool(0);
        (,uint256 Block,uint256 alloc) = (masterChefV.poolInfo(0));
        assertEq(100,Block);

        uint256 masterChef2 = sushi.balanceOf(address(masterChefV));
        assertEq(masterChef2,9900 ether );

    }
    
    function testMassUpdatePools() public {
        uint256[] memory pids = new uint256[](1);
        pids[0] = 0;
        setUpMasterChefV(5 ether, 100, 0);
        masterChefV.massUpdatePools(pids);
        (,uint256 Block,uint256 alloc) = (masterChefV.poolInfo(0));
        assertEq(100,Block);

        uint256 masterChef2 = sushi.balanceOf(address(masterChefV));
        assertEq(masterChef2,9900 ether );
       
    }

    function testEmergencyWithdraw() public{
        setUpMasterChefV(5 ether, 100, 0);
        uint256 stakerbalancebefore = lp.balanceOf(address(this));
        masterChefV.emergencyWithdraw(0,address(this));
        uint256 stakerbalanceafter = lp.balanceOf(address(this));
        uint256 rewardsOfThis = masterChefV.pendingSushi(0,address(this));
        assertEq(stakerbalanceafter,5 ether);
        assertEq(stakerbalancebefore,0);
        assertEq(rewardsOfThis,0);
    }

    function testPoolLength() public {
        uint256 lenght = masterChefV.poolLength();
        assertEq(lenght,1);
    }

    function testTotalAllocPoint() public {
        
        uint256 alloc = masterChefV.totalAllocPoint();
        assertEq(alloc, 1000);
    }

    function setUpMasterChefV(uint256 amount, uint256 blocknumber,uint256 pid) public{
        lp.mint(address(this),amount);
        lp.approve(address(masterChefV),amount);
        masterChefV.deposit(pid,amount,address(this));

        vm.roll(blocknumber);//rolls block.number
    }

}