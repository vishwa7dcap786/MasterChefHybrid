// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {SushiToken} from "./SushiToken.sol";
import {MasterChef,IMigratorChef,sushiToken} from "../src/MasterChef.sol";
import {MasterChefV2,IMasterChef} from "../src/MasterChefV2.sol";
import {IERC20} from "../src/IERC20.sol";
import {Migrator} from "./Migrator.sol";
import {LpToken} from "./LpToken.sol";


contract CounterTest is Test {
    SushiToken public sushi;
    MasterChef public masterChefV1;
    MasterChefV2 public masterChefV2;
    LpToken public lp;
    address public USER = makeAddr("user");
    function setUp() public {
        sushi = new SushiToken();
        lp = new LpToken("LP","lp");
        masterChefV1 = new MasterChef(sushiToken(address(sushi)),USER,100 ether,block.number,0);
        sushi.setAuthorizedMinter(address(masterChefV1),true);
        masterChefV1.add(1000,IERC20(address(lp)),true);
        masterChefV2 = new MasterChefV2(IMasterChef(address(masterChefV1)),IERC20(address(sushi)),0);
        

    }

    function testMigrate() public {
        setUpMasterChefV1(5 ether, 100, 0);
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        lpM.mint(address(migrator),5 ether);
        masterChefV1.setMigrator(IMigratorChef(address(migrator)));
        masterChefV1.migrate(0);
        assertEq(lpM.balanceOf(address(masterChefV1)),5 ether);

    }

    function testMigratorToken() public {
        LpToken lpM = new LpToken("newLP","newlp");
        Migrator migrator = new Migrator(address(lpM));
        address token = address(migrator.tokenToMigrate());
        assertEq(token, address(lpM));
    }

    
    function testMasterchefV1Pool() public {
        
        (IERC20 lpToken,,,) = (masterChefV1.poolInfo(0));
        assertEq(address(lp),address(lpToken));
    }

    function testSushiMinted() public {

        // console.log(block.timestamp);//skips timestamp
        // skip(3600);
        // console.log(block.timestamp);
        
        setUpMasterChefV1(5 ether,100,0);

        masterChefV1.updatePool(0);
        (IERC20 lpToken,uint256 alloc,uint256 Block,) = (masterChefV1.poolInfo(0));
        assertEq(100,Block);

        uint256 devBalance = sushi.balanceOf(USER);
        uint256 masterChef1 = sushi.balanceOf(address(masterChefV1));
        assertEq(masterChef1,9900 ether);
        assertEq(devBalance,9900 ether/10);
    }

    function testSet() public{
        masterChefV1.set(0,10000,false);
        (IERC20 lpToken,uint256 alloc,uint256 Block,) = (masterChefV1.poolInfo(0));
        assertEq(masterChefV1.totalAllocPoint(),10000);
        assertEq(alloc,10000);
    }

    function testDeposit() public {
        setUpMasterChefV1(5 ether, 100, 0);
        (uint256 amount, uint256 rewardDept) = masterChefV1.userInfo(0,address(this));
        assertEq(amount,5 ether);
        assertEq(rewardDept,0);
    }

    function testWithdraw() public {
        setUpMasterChefV1(5 ether, 100, 0);
        uint256 rewards = masterChefV1.pendingSushi(0,address(this));
        masterChefV1.withdraw(0,5 ether);
        uint256 rewardsReceived = sushi.balanceOf(address(this));
        assertEq(rewardsReceived,rewards);
    }

    function testEmergencyWithdraw() public{
        setUpMasterChefV1(5 ether, 100, 0);
        uint256 stakerbalancebefore = lp.balanceOf(address(this));
        masterChefV1.emergencyWithdraw(0);
        uint256 stakerbalanceafter = lp.balanceOf(address(this));
        uint256 rewardsOfThis = masterChefV1.pendingSushi(0,address(this));
        assertEq(stakerbalanceafter,5 ether);
        assertEq(stakerbalancebefore,0);
        assertEq(rewardsOfThis,0);
    }



    function testpendingSushi() public {

        setUpMasterChefV1(5 ether, 100, 0);
        uint256 rewardsOfThis = masterChefV1.pendingSushi(0,address(this));
        assertEq(rewardsOfThis,9900 ether);
    }

    function testMassUpdatePools() public {
        setUpMasterChefV1(5 ether, 100, 0);
        masterChefV1.massUpdatePools();
        (IERC20 lpToken,uint256 alloc,uint256 Block,) = (masterChefV1.poolInfo(0));
        assertEq(100,Block);

        uint256 devBalance = sushi.balanceOf(USER);
        uint256 masterChef1 = sushi.balanceOf(address(masterChefV1));
        assertEq(masterChef1,9900 ether);
        assertEq(devBalance,9900 ether/10);
    }

    function testPoolLength() public {
        uint256 lenght = masterChefV1.poolLength();
        assertEq(lenght,1);
    }

    function testGetMultiplier() public {
        uint256 blocks = masterChefV1.getMultiplier(1, 100);
        assertEq(blocks,99);
    }


    function setUpMasterChefV1(uint256 amount, uint256 blocknumber,uint256 pid) public{
        lp.mint(address(this),amount);
        lp.approve(address(masterChefV1),amount);
        masterChefV1.deposit(pid,amount);

        vm.roll(blocknumber);//rolls block.number
    }

}
