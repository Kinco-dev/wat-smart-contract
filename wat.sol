
// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        recipient.call{value: amount}("");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


interface IFactory02 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IPair02 {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract WeAreTogether is ERC20, Ownable {
   
    using Address for address payable;

    mapping (address => bool) private _isExcludedFromFees;

    // Sell fees
    uint16 public lpSellFee = 100;
    uint16 public teamSellFee = 500;
    uint16 public buyBackSellFee = 400;
    uint16 public totalSellFees = 1000;
    uint16 public constant MAX_SELL_FEES = 1000;

    // Buy fees
    uint16 public lpBuyFee = 100;
    uint16 public teamBuyFee = 400;
    uint16 public buyBackBuyFee = 300;
    uint16 public totalBuyFees = 800;
    uint16 public constant MAX_BUY_FEES = 800;

    uint16 public constant BASE_BP_FEES = 10_000;

    // Allows to know the distribution of tokens collected from taxes
    uint256 private _lpCurrentAccumulatedFees;
    uint256 private _teamCurrentAccumulatedFees;

    IRouter02 public dexRouter;
    address public dexPair;
    
    bool private _inSwapAndLiquify;
    
    uint256 public swapThreshold =  30_000*10**18; // 0.01%

    // All known liquidity pools 
    mapping (address => bool) public automatedMarketMakerPairs;

    address payable public buyBackWallet;
    address payable public teamWallet;
    address public liquidityWallet;
    address constant private  DEAD = 0x000000000000000000000000000000000000dEaD;

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event AddAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event Router02Updated(address indexed newAddress, address indexed oldAddress);

    event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event BuyBackWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event LiquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event Burnt(uint256 amount);

    event BuyFeesUpdated(uint256 newLpFee, uint256 newTeamfee, uint256 newBuyBackFee);
    event SellFeesUpdated(uint256 newLpFee, uint256 newTeamfee, uint256 newBuyBackFee);

    event SwapThresholdUpdated(uint256 amount);

    event Swap(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    constructor(address payable _teamWallet, address payable _buyBackWallet, address _liquidityWallet) ERC20("We Are Together", "WAT") Ownable(_msgSender()) {

        _mint(_msgSender(), 300_000_000 * 10**18);

        teamWallet = _teamWallet;
        buyBackWallet = _buyBackWallet;
        liquidityWallet = _liquidityWallet;

        dexRouter = IRouter02(0xDE2Db97D54a3c3B008a097B2260633E6cA7DB1AF); // TODO replace router
        dexPair = IFactory02(dexRouter.factory())
            .createPair(address(this), dexRouter.WETH());

        _setAutomatedMarketMakerPair(dexPair, true);
        excludeFromFees(owner(),true);
        excludeFromFees(address(this),true);
        excludeFromFees(buyBackWallet, true);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "WAT: Account has already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != dexPair, "WAT: The main pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "WAT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit AddAutomatedMarketMakerPair(pair, value);
    }

    function updateV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(dexRouter), "WAT: The router has already that address");
        emit Router02Updated(newAddress, address(dexRouter));
        dexRouter = IRouter02(newAddress);
        address newPair = IFactory02(dexRouter.factory()).getPair(address(this), dexRouter.WETH());
        if (newPair == address(0)) {
            newPair = IFactory02(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        }
        dexPair = newPair;

        _setAutomatedMarketMakerPair(dexPair, true);
    }

    function setBuyFees(uint16 newLpFee, uint16 newTeamFee, uint16 newBuyBackFee) external onlyOwner {
        uint16 newTotalFees = newLpFee + newTeamFee + newBuyBackFee;
        require(newTotalFees <= MAX_BUY_FEES ,"WAT: Total fees must be lower than 8%");
        lpBuyFee = newLpFee;
        teamBuyFee = newTeamFee;
        buyBackBuyFee = newBuyBackFee;
        totalBuyFees = newTotalFees;
        emit BuyFeesUpdated(newLpFee, newTeamFee, newBuyBackFee);
    }

    function setSellFees(uint16 newLpFee, uint16 newTeamFee, uint16 newBuyBackFee) external onlyOwner {
        uint16 newTotalFees = newLpFee + newTeamFee + newBuyBackFee;
        require(newTotalFees <= MAX_SELL_FEES ,"WAT: Total fees must be lower than 10%");
        lpSellFee = newLpFee;
        teamSellFee = newTeamFee;
        buyBackSellFee = newBuyBackFee;
        totalSellFees = newTotalFees;
        emit SellFeesUpdated(newLpFee, newTeamFee, newBuyBackFee);
    }

    function setSwapThreshold(uint256 amount) external onlyOwner {
        require(amount <= totalSupply()/(100 * 10**18), "WAT: Amount must be lower (or equals) than 1% of the total supply");
        swapThreshold = amount *10**18;
        emit SwapThresholdUpdated(swapThreshold);
    }

    function setTeamWallet(address payable newWallet) external onlyOwner {
        require(newWallet != teamWallet, "WAT: The team wallet has already this address");
        require(newWallet != address(0), "WAT: The team wallet cannot be the zero address");
        emit TeamWalletUpdated(newWallet,teamWallet);
        teamWallet = newWallet;
    }

    function setLiquidityWallet(address payable newWallet) external onlyOwner {
        require(newWallet != liquidityWallet, "WAT: The liquidity wallet has already this address");
        require(newWallet != address(0), "WAT: The liquidity wallet cannot be the zero address");
        emit LiquidityWalletUpdated(newWallet,liquidityWallet);
        liquidityWallet = newWallet;
    }

    function setBuyBackWallet(address payable newWallet) external onlyOwner {
        require(newWallet != buyBackWallet, "WAT: The buyBack wallet has already this address");
        require(newWallet != address(0), "WAT: The buyback wallet cannot be the zero address");
        emit BuyBackWalletUpdated(newWallet,buyBackWallet);
        buyBackWallet = newWallet;
    }

    function burn(uint256 amount) external returns (bool) {
        _transfer(_msgSender(), DEAD, amount);
        emit Burnt(amount);
        return true;
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "WAT: Transfer from the zero address");
        require(to != address(0), "WAT: Transfer to the zero address");

        bool isBuyTransfer = automatedMarketMakerPairs[from];
        bool isSellTransfer = automatedMarketMakerPairs[to];

        bool takeFee = !_inSwapAndLiquify && (isBuyTransfer || isSellTransfer);

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;


        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapThreshold;

        if (
            canSwap &&
            !_inSwapAndLiquify&&
            !automatedMarketMakerPairs[from] // not during buying
        ) {
            _swapAndDistribute(swapThreshold);
        }

        uint256 amountWithoutFees = amount;
        if(takeFee) {
            // Buy
            if(isBuyTransfer){
                amountWithoutFees = amount - amount * totalBuyFees / BASE_BP_FEES;
                _lpCurrentAccumulatedFees += amount * lpBuyFee / BASE_BP_FEES;
                _teamCurrentAccumulatedFees += amount * teamBuyFee / BASE_BP_FEES;
            }
            // Sell 
            else if(isSellTransfer)  {
                amountWithoutFees = amount - amount * totalSellFees / BASE_BP_FEES;
                _lpCurrentAccumulatedFees += amount * lpSellFee / BASE_BP_FEES;
                _teamCurrentAccumulatedFees += amount * teamSellFee / BASE_BP_FEES;

            }
            if(amountWithoutFees != amount) super._transfer(from, address(this), amount - amountWithoutFees);
        }
        super._transfer(from, to, amountWithoutFees);

    }

    function _swapAndDistribute(uint256 tokenAmount) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        uint256 totalTokenBalance = balanceOf(address(this));

        uint256 tokensToNotSwap = _lpCurrentAccumulatedFees / 2 * tokenAmount / totalTokenBalance;
        uint256 tokensToSwap =  tokenAmount - tokensToNotSwap;
        // Swap tokens for BNB
        _swapTokensForBNB(tokensToSwap);
        uint256 newBalance = address(this).balance - initialBalance;

        // LP
        uint256 lpAmount = newBalance * tokensToNotSwap / tokensToSwap;
        if(lpAmount > 0) addLiquidity(tokensToNotSwap,lpAmount);
         _lpCurrentAccumulatedFees -= tokensToNotSwap*2;

        // Team
        uint256 teamTokenAmount = _teamCurrentAccumulatedFees * tokenAmount / totalTokenBalance;
        uint256 teamAmount = newBalance * teamTokenAmount / tokensToSwap;
        teamWallet.sendValue(teamAmount);
         _teamCurrentAccumulatedFees -=teamTokenAmount;

        // BuyBack
        uint256 buybackAmount = address(this).balance - initialBalance;
        buyBackWallet.sendValue(buybackAmount);

        emit Swap(tokensToSwap, newBalance);
        
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndDistribute(uint256 amount) public onlyOwner {
        require(!_inSwapAndLiquify, "WAT: Contract is already swapping");
        require(amount > 0, "WAT: Amount must be greater than 0");

        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance >= amount, "WAT: Not enough tokens to swap");

        _swapAndDistribute(amount);
        
    } 
    // To distribute airdrops easily
    function batchTokensTransfer(address[] calldata _holders, uint256[] calldata _amounts) external {
        require(_holders.length <= 100);
        require(_holders.length == _amounts.length);
            for (uint i = 0; i < _holders.length; i++) {
              if (_holders[i] != address(0)) {
                super._transfer(_msgSender(), _holders[i], _amounts[i]);
            }
        }
    }

    function withdrawStuckBNB(address payable to) external onlyOwner {
        require(address(this).balance > 0, "WAT: There are no BNB in the contract");
        to.sendValue(address(this).balance);
    } 

    function withdrawStuckERC20Tokens(address token, address to, uint256 amount) external onlyOwner {
        require(token != address(this), "WAT: You are not allowed to get WAT tokens from the contract");
        require(IERC20(token).balanceOf(address(this)) > 0, "WAT: There are no tokens in the contract");
        require(IERC20(token).transfer(to, amount));
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(address(0));
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

  
}