# LifeBot

# MODULES
params = require "params"
trading = require "trading"
# ds = require "datasources" #Pro+ only

# PARAMS
_spread = params.add "Spread ($) [.01+; 0=disabled; try 25?]", 0
_trendNumBuy = params.add "Consecutive trend num to BUY (1+)", 5
_trendNumSell = params.add "Consecutive trend num to SELL (1+)", 1
_makerBufferMult = params.add "Maker trade buffer (multiplier)", .001
_makerBufferCurr = params.add "Maker trade buffer ($) [only if above is 0]", .1
_maximumExchangeFee = params.add "Maximum exchange fee %", 0
_maximumOrderAmount = params.add "Maximum order amount", 10
_orderTimeout = params.add "Order timeout", 55
_plotBuy = params.add "Plot buy indicator", true
_plotSell = params.add "Plot sell indicator", true
_verbose = params.add "Verbose", true

# CONSTS
MINIMUM_AMOUNT = .01
SELLOFF_PRICE = 100

# FUNCTIONS
interval2period: (interval) ->
  pn = 0
  pt = ""
  if interval >= 1440
    pn = interval/1440
    pt = "d"
  else if interval >= 60
    pn = interval/60
    pt = "h"
  else
    pn = interval
    pt = "m"

  return "" + pn + pt

init: (context)->
  #This runs once when the bot is started
  setPlotOptions
    sellIndicator:
      color: 'red'
    buyIndicator:
      color: 'green'
    sell:
      color: 'orange'
    buy:
      color: 'lime'

#   context.configPeriod = interval2period(@config.interval)
#   ds.add @config.market, @config.pair, context.configPeriod
#   ticks = ds.get @config.market, @config.pair, context.configPeriod
#   ticker = trading.getTicker ticks
#   storage.priceLast = ticker.buy
#   debug "Starting price: #{storage.priceLast}"

doBuy: (ins, amt, price, currencyAvailable) ->
  if (_plotBuy)
    plotMark
      buyIndicator: ins.price
  if (amt >= MINIMUM_AMOUNT)
    orderAmt = Math.min(_maximumOrderAmount, amt)
    debug "Buy: #{orderAmt} * #{price} [currencyAvailable: #{currencyAvailable}]"
    storage.tradesAttempted++
    try
      if trading.buy ins, 'limit', orderAmt, price, _orderTimeout
        storage.tradesActual++
    catch e
      if /insufficient funds/i.exec e
        debug "Error: Insufficient Funds. orderAmt #{orderAmt}; price #{price}; currency needed #{orderAmt * price}; currencyAvailable #{currencyAvailable};"
      else
        throw e # rethrow unhandled exception

doSell: (ins, amt, price) ->
  if (_plotSell)
    plotMark
      sellIndicator: ins.price
  if (amt >= MINIMUM_AMOUNT)
    orderAmt = Math.min(_maximumOrderAmount, amt)
    debug "Sell: #{orderAmt} * #{price}"
    storage.tradesAttempted++
    if trading.sell ins, 'limit', orderAmt, price, _orderTimeout
      storage.tradesActual++

handle: (context, data, storage)->
  #This runs once every tick or bar on the graph
  storage.botStartedAt ?= data.at
  storage.priceLast ?= 0
  storage.buyPriceMktLast ?= 0
  storage.sellPriceMktLast ?= 0
  storage.trend ?= 0
  storage.tradesActual ?= 0
  storage.tradesAttempted ?= 0

  ins = data.instruments[0]
  ticker = trading.getTicker ins
  portfolio = @portfolios[ins.market]

  assetsAvailable = portfolio.positions[ins.asset()].amount
  currencyAvailable = portfolio.positions[ins.curr()].amount
  storage.priceInit ?= ins.price
  storage.valueInit ?= currencyAvailable + (assetsAvailable * ins.price)
  storage.assetsAvailableStart ?= assetsAvailable
  storage.assetsAvailableLast = assetsAvailable
  storage.currencyAvailableStart ?= currencyAvailable
  storage.currencyAvailableLast = currencyAvailable
  if (_verbose)
    debug "price: #{ins.price}; buy: #{ticker.buy}; sell: #{ticker.sell}"

  buyPriceMkt = ticker.buy
  sellPriceMkt = ticker.sell
#   buyPriceMkt = sellPriceMkt = ins.price # comment this out if you wanna; only affects live

  buyPrice = (buyPriceMkt * (1 - _makerBufferMult))
  sellPrice = (sellPriceMkt * (1 + _makerBufferMult))
  if (!_makerBufferMult && _makerBufferCurr)
    buyPrice = (buyPriceMkt - _makerBufferCurr)
    sellPrice = (sellPriceMkt + _makerBufferCurr)

  maximumBuyAmount = calcAfterFees (currencyAvailable/buyPrice)
  maximumSellAmount = calcAfterFees assetsAvailable
  isPriceSame = (ins.price == storage.priceLast)

  if (ins.price < SELLOFF_PRICE) # sell off
    warn "SELLOFF!"
    doSell ins, maximumSellAmount, sellPrice
  else if (storage.priceLast <= 0) # do nothing
  else if (_spread > 0) # spread mode
    if (currencyAvailable > 0)
      buyPrice = buyPriceMkt - _spread
      maximumBuyAmount = calcAfterFees (currencyAvailable/buyPrice) # have to recalc
      doBuy ins, maximumBuyAmount, buyPrice, currencyAvailable
    else if (assetsAvailable > 0)
      sellPrice = sellPriceMkt + _spread
      doSell ins, maximumSellAmount, sellPrice
  else if (!isPriceSame) # trend mode
    if (ins.price == storage.priceLast)
    else if (ins.price > storage.priceLast)
      storage.trend = Math.max(storage.trend, 0) + 1
    else if (ins.price < storage.priceLast)
      storage.trend = Math.min(storage.trend, 0) - 1

    if (storage.trend == 0)
    else if (storage.trend >= _trendNumBuy)
      doBuy ins, maximumBuyAmount, buyPrice, currencyAvailable
    else if (storage.trend <= (_trendNumSell * -1))
      doSell ins, maximumSellAmount, sellPrice

  storage.priceLast = ins.price
  storage.buyPriceMktLast = buyPriceMkt
  storage.sellPriceMktLast = sellPriceMkt

onRestart: ->
  debug "Bot restarted at #{new Date(data.at)}"

onStop: ->
  debug "Bot started at #{new Date(storage.botStartedAt)}"
  debug "Bot stopped at #{new Date(data.at)}"
  debug "Total trades: #{storage.tradesActual} actual (#{storage.tradesAttempted} attempted)"
  valueFinal = storage.currencyAvailableLast + (storage.assetsAvailableLast * storage.priceLast)

  myPL = valueFinal / storage.valueInit
  myPLPct = (myPL - 1) * 100
  printNumeric myPLPct, "My Profit/Loss: #{myPLPct.toFixed? 2}% (#{valueFinal} / #{storage.valueInit})"

  marketPL = storage.priceLast / storage.priceInit
  marketPLPct = (marketPL - 1) * 100
  printNumeric marketPLPct, "Market: #{marketPLPct.toFixed? 2}% (#{storage.priceLast} / #{storage.priceInit})"

  meVsMarket = myPLPct - marketPLPct
#   meVsMarketPct = (meVsMarket - 1) * 100
  printNumeric meVsMarket, "Me vs Market: #{meVsMarket.toFixed? 2}% (#{myPLPct} - #{marketPLPct})"

calcAfterFees: (val) ->
  val = val * (1 - (_maximumExchangeFee/100))
  val

printNumeric: (num, message, isEvenDebug = false) ->
  if (isEvenDebug && (num == 0))
    debug message
  else if (num > 0)
    info message
  else
    warn message

rounder: (val, pow = 2) ->
  tens = Math.pow(10, pow)
  val = Math.floor(tens * val) / tens
  val
