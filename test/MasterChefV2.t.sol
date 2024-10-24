// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {SushiToken} from "./SushiToken.sol";
import {MasterChef,sushiToken} from "../src/MasterChef.sol";
import {MasterChefV2,IMasterChef,IMigratorChef,IRewarder} from "../src/MasterChefV2.sol";
import {IERC20} from "../src/IERC20.sol";
import {Migrator} from "./Migrator.sol";


import {LpToken} from "./LpToken.sol";


contract CounterTest is Test {
    SushiToken public sushi;
    MasterChef public masterChefV1;
    MasterChefV2 public masterChefV2;
    LpToken public dummyToken;
    LpToken public lp;
    address public USER = makeAddr("user");
    function setUp() public {
        //MasterChefV1 setUp
        sushi = new SushiToken();
        dummyToken = new LpToken("DummyToken","dummyToken");
        masterChefV1 = new MasterChef(sushiToken(address(sushi)),USER,100 ether,block.number,0);
        sushi.setAuthorizedMinter(address(masterChefV1),true);
        masterChefV1.add(1000,IERC20(address(dummyToken)),true);
        //MasterChefV2 setUp
        lp = new LpToken("Lp","lp");
        masterChefV2 = new MasterChefV2(IMasterChef(address(masterChefV1)),IERC20(address(sushi)),0);
        dummyToken.mint(address(this), 10000 ether);
        dummyToken.approve(address(masterChefV2),dummyToken.balanceOf(address(this)));
        masterChefV2.init(IERC20(address(dummyToken)));  
        masterChefV2.add(1000,IERC20(address(lp)),IRewarder(address(0)));

    }
    

    function testMigrate() public {
        setUpMasterChefV2(5 ether, 100, 0);
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        lpM.mint(address(migrator),5 ether);
        masterChefV2.setMigrator(IMigratorChef(address(migrator)));
        masterChefV2.migrate(0);
        assertEq(lpM.balanceOf(address(masterChefV2)),5 ether);

    }

    function testMigratorToken() public {
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        address token = address(migrator.tokenToMigrate());
        assertEq(token, address(lpM));
    }

    


    function testSushiPerBlock() public {
        uint256 sushiPerBlock = masterChefV2.sushiPerBlock();
        assertEq(sushiPerBlock, 100 ether);
    }

    function testSet() public{
        masterChefV2.set(0,1000,IRewarder(address(0)),false);
        (uint128 accSushiPerShare,uint64 lastRewardBlock,uint64 allocPoint) = (masterChefV2.poolInfo(0));
        assertEq(masterChefV2.totalAllocPoint(),1000);
        assertEq(allocPoint,1000);
    }

    function testDeposit() public {
        setUpMasterChefV2(5 ether, 100, 0);
        (uint256 amount, int256 rewardDept) = masterChefV2.userInfo(0,address(this));
        assertEq(amount,5 ether);
        assertEq(rewardDept,0);
    }

    function testHarvestFromMasterChefAsAnyone() public {
        setUpMasterChefV2(5 ether, 100, 0);
        harvestFromMasterChefAsAnyone();
        uint256 balanceOfMasterv2 = sushi.balanceOf(address(masterChefV2));
        assertEq(balanceOfMasterv2,9900 ether);
    }

    function testWithdraw() public {
        setUpMasterChefV2(5 ether, 100, 0);
        masterChefV2.withdraw(0, 3 ether, address(this));
        uint256 amountreceived = lp.balanceOf(address(this));
        uint256 rewards = masterChefV2.pendingSushi(0,address(this));
        (uint256 amount, int256 rewardDept) = masterChefV2.userInfo(0,address(this));       
        assertEq(rewards,9900 ether);
        assertEq(amountreceived,3 ether);
        assertEq(amount, 2 ether);
        assertEq(rewardDept,-5940000000000000000000);

    }

    function testHarvest() public {
        setUpMasterChefV2(5 ether, 100, 0);
        masterChefV2.withdraw(0, 3 ether, address(this));
        harvestFromMasterChefAsAnyone();
        masterChefV2.harvest(0,address(this));
        uint256 rewardsReceived = sushi.balanceOf(address(this));
        assertEq(rewardsReceived, 9900 ether);
    }

    function testWithdrawAndHarvest() public {
        setUpMasterChefV2(5 ether, 100, 0);
        harvestFromMasterChefAsAnyone();
        masterChefV2.withdrawAndHarvest(0, 3 ether, address(this));
        uint256 rewardsReceived = sushi.balanceOf(address(this));
        uint256 amountreceived = lp.balanceOf(address(this));
        assertEq(rewardsReceived, 9900 ether);
        assertEq(amountreceived, 3 ether);
    }

    function testpendingSushi() public {

        setUpMasterChefV2(5 ether, 100, 0);
        uint256 rewardsOfThis = masterChefV2.pendingSushi(0,address(this));
        assertEq(rewardsOfThis,9900 ether);
    }

    function testupdatePool() public {
        setUpMasterChefV2(5 ether, 100, 0);
        masterChefV2.updatePool(0);
        (,uint256 Block,uint256 alloc) = (masterChefV2.poolInfo(0));
        assertEq(100,Block);

        uint256 masterChef2 = sushi.balanceOf(address(masterChefV2));
        assertEq(masterChef2,0 );

    }
    
    function testMassUpdatePools() public {
        uint256[] memory pids = new uint256[](1);
        pids[0] = 0;
        setUpMasterChefV2(5 ether, 100, 0);
        masterChefV2.massUpdatePools(pids);
        (,uint256 Block,uint256 alloc) = (masterChefV2.poolInfo(0));
        assertEq(100,Block);

        uint256 masterChef2 = sushi.balanceOf(address(masterChefV2));
        assertEq(masterChef2,0 );
       
    }

    function testEmergencyWithdraw() public{
        setUpMasterChefV2(5 ether, 100, 0);
        uint256 stakerbalancebefore = lp.balanceOf(address(this));
        masterChefV2.emergencyWithdraw(0,address(this));
        uint256 stakerbalanceafter = lp.balanceOf(address(this));
        uint256 rewardsOfThis = masterChefV2.pendingSushi(0,address(this));
        assertEq(stakerbalanceafter,5 ether);
        assertEq(stakerbalancebefore,0);
        assertEq(rewardsOfThis,0);
    }

    function testPoolLength() public {
        uint256 lenght = masterChefV2.poolLength();
        assertEq(lenght,1);
    }

    function testTotalAllocPoint() public {
        
        uint256 alloc = masterChefV2.totalAllocPoint();
        assertEq(alloc, 1000);
    }

    function setUpMasterChefV2(uint256 amount, uint256 blocknumber,uint256 pid) public{
        lp.mint(address(this),amount);
        lp.approve(address(masterChefV2),amount);
        masterChefV2.deposit(pid,amount,address(this));

        vm.roll(blocknumber);//rolls block.number
    }

    function harvestFromMasterChefAsAnyone() public {
        masterChefV2.harvestFromMasterChef();
    }

}