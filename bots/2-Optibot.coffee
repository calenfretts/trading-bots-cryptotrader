# Optibot
# self-optimizing TAlib bot (ADX/AROON/BBANDS/CCI/MA/MACD/MFI/RSI/STOCH/STOCHRSI/etc)

# MODULES
params = require "params"
talib = require "talib"
trading = require "trading"
#ds  = require "datasources" #Pro+ only

# CONSTS
GLOBAL = @ # for reference in classes
PERIOD_DEF = 14
LAG_DEF = 0
MATYPE_DEF = 0
DO_OBSCURE = true # obscure "premium" info (for "free" backtests)
FIXED_LEN_F = 2#fiat
FIXED_LEN_A = 10#crypto assets
ADVICE_IND_MULT = .90
MIN_AMOUNT = .01
FUNC_LIST_ALL = "+"
FUNC_LIST_DEF = FUNC_LIST_ALL
FUNC_SOLO_ALL = "-"
FUNC_SOLO_DEF = "STOCH"#FUNC_SOLO_ALL
INS_TYPE_A = "ASSET"
INS_TYPE_B = "BASE"
INS_TYPE_C = "CURR"
TRADE_TYPE_L = "limit"
TRADE_TYPE_M = "market"
OPTI_TRADE_MODE_ID = "=> OPTI <="
ACTION_BUY = "buy"
ACTION_SELL = "sell"

# INITIAL VARS/FUNCS
symbolsFiat = ["USD", "USDT", "EUR", "GBP", "CNY", "JPY"]

talibFuncOpts = ["AROON", "BBANDS", "CCI", "DX", "MA", "MACD", "MFI", "RSI", "STOCH", "STOCHRSI"]

optInMATypeOpts = {
  0: "SMA (Simple Moving Average)",
  1: "EMA (Exponential Moving Average)",
  2: "WMA (Weighted Moving Average)",
  3: "DEMA (Double Exponential Moving Average)",
  4: "TEMA (Triple Exponential Moving Average)",
  5: "TRIMA (Triangular Moving Average)",
  6: "KAMA (Kaufman Adaptive Moving Average)",
  #7: "MAMA (MESA Adaptive Moving Average)",# doesn't work (different params)
  8: "T3 (Triple Exponential Moving Average)",
}
optInMATypeOptsKeys = _.keys(optInMATypeOpts)

optInMATypeMore = "/"
for k, v of optInMATypeOpts
  optInMATypeMore += " " + k + ": " + v + " /"

optInMATypeDef =
#   switch
#   when (@config.interval <= 15) then 4
#   else MATYPE_DEF
  MATYPE_DEF

xcFeesMaker = {#updated 8/25/17
  "poloniex": 0.15,#https://poloniex.com/fees/
  "bitstamp": 0.25,#https://www.bitstamp.net/fee_schedule/
  "coinbase": 0,#https://www.gdax.com/fees/
  "huobi": 0.1,#foreign
  "okcoin": 0,#foreign
  "btce": 0.2,#dead
  "cexio": 0,#https://cex.io/fee-schedule
  "bitfinex": 0.1,#https://www.bitfinex.com/fees
  "kraken": 0.16,#https://www.kraken.com/help/fees
  "bittrex": 0.25,#https://bittrex.com/fees
  "binance": 0.1,#https://www.binance.com/fees.html
  "quoine": 0,#https://quoinex.com/fees/
  "cryptsy": 0.25,#dead
}

configFeeDef = xcFeesMaker[@config.market] ? .1

# CLASSES
class Fns # doesn't use App or context/storage/etc
  @toInt: (num) ->
    return parseInt(num, 10)

  @debugIt: (obj, method = warn) ->
    for k, v of obj
      method "#{k} = #{v}"

  @isSet: (obj) ->
    return (typeof obj != "undefined")

  @doPrintSettings: (pm, p) ->
    warn "======= SETTINGS ======="
    for k, v of pm
      if !v
        continue
      debug v.t + ": " + p[k]
    warn "======= /SETTINGS ======="

  @interval2period: (interval) -> # interval in minutes
    pn = 0
    pt = ""
    if interval >= 1440
      pn = interval / 1440
      pt = "d"
    else if interval >= 60
      pn = interval / 60
      pt = "h"
    else
      pn = interval
      pt = "m"

    return "" + pn + pt

  @interval2historyVsOpti: (interval) -> # interval in minutes
    ans = 0
    return ans

    MINS_HOUR = 60
    MINS_DAY = MINS_HOUR * 24 # 1440
    if interval >= MINS_DAY
      ans = 3 * (interval / MINS_DAY)
    else if interval >= MINS_HOUR
      ans = 12 / (interval / MINS_HOUR)
    else
      ans = 60 / interval

    return @toInt(ans)

  @getBalance: (currBal, assetBal, price) ->
    return (currBal + (assetBal * price))

  @formatPct: (val, incSym = true) ->
    val = val.toFixed(2)
    if incSym
      val += "%"
    return val

  @roundTo: (amount, place, roundDir = -1) ->
    funcHandle = if (roundDir == -1) then Math.floor else if (roundDir == 1) then Math.ceil else if (roundDir == 0) then Math.round else throw new Error("invalid roundTo roundDir")
    tens = Math.pow(10, place)
    return (funcHandle(amount * tens) / tens)

  @exAs: (obj, prop, val) -> # existential assignment
    if !@isSet(obj)
      App.die("exAs: obj undefined")

    if !@isSet(obj[prop])
      obj[prop] = val
    else
      obj[prop] ?= val

  @getIncreasePct: (valInit, valFinal) ->
    return (((valFinal / valInit) - 1) * 100)

  @printNumeric: (num, message, isEvenDebug = true) ->
    if isEvenDebug and (num == 0)
      debug message
    else if (num > 0)
      info message
    else
      warn message

  @assert: (condition, message) ->
    if !condition
      message = message or "Assertion failed"
      if @isSet(Error)
        throw new Error(message)
      throw message # fallback

  @diff: (x, y) ->
    100 * ((x - y) / ((x + y) / 2))
#/class Fns

class App # DOES use App or context/storage/etc
  @stopHard: ->
    context.stopHard = true
    stop()

  @die: (msg = "Dead!") ->
    #throw new Error(msg)# execution ends here
    warn msg
    @stopHard()

  @getAmount: (ins, type) ->
    typeActual = switch type
      when INS_TYPE_A then ins.asset()
      when INS_TYPE_B then ins.base()
      when INS_TYPE_C then ins.curr()
      else @die("Invalid argument (#{type}) in getAmount " + arguments.callee.name)

    ans = GLOBAL.portfolios[ins.market].positions[typeActual].amount
    if (type == INS_TYPE_C)
      ans = @roundCurr(ans)
    return ans

  @getBalanceOfId: (id, ins, ticksAgo = null) ->
    if ticksAgo? and Number.isInteger(ticksAgo) and storage.histBal[id]?.length
      return storage.histBal[id][Math.min(ticksAgo, storage.histBal[id].length - 1)]
    return Fns.getBalance(storage.currBal[id], storage.assetBal[id], ins.price)

  @formatCurr: (val, incSym = true) ->
    val = val.toFixed(context.currDecLen)
    if incSym
      val += " #{context.currUp}"
    return val

  @formatAsset: (val, incSym = true) ->
    val = val.toFixed(context.assetDecLen)
    if incSym
      val += " #{context.assetUp}"
    return val

  @roundAsset: (amount, roundDir = -1) ->
    return Fns.roundTo(amount, context.assetDecLen, roundDir)

  @roundCurr: (amount, roundDir = -1) ->
    return Fns.roundTo(amount, context.currDecLen, roundDir)

  @calcFeeCurr: (amount) ->
    return @roundCurr((context.actualFeePct * amount), 1)

  @calcFeeAsset: (amount) ->
    return @roundAsset((context.actualFeePct * amount), 1)

  @checkOptiTrade: (ins) ->
    traders = _.union(Object.keys(storage.numSells), Object.keys(storage.numBuys))
    if !context.opti_funcId? and (traders.length <= 0)
      return # no trades yet, not ready!

    isOptiHistoryVsMode = p.opti_historyVs? and (storage.numTicks >= p.opti_historyVs)
    highBal = if isOptiHistoryVsMode then 0 else if context.opti_funcId? then @getBalanceOfId(OPTI_TRADE_MODE_ID, ins) else storage.totalBalInit
    opti_funcIdPrev = context.opti_funcId
    for id in traders
      if (id == OPTI_TRADE_MODE_ID)
        continue

      totalBal = @getBalanceOfId(id, ins)
      histBal = 0
      if isOptiHistoryVsMode
        storage.histBal[id].unshift(totalBal)
        if (storage.histBal[id]?.length > p.opti_historyVs)
          storage.histBal[id].pop()
        histBal = @getBalanceOfId(id, ins, p.opti_historyVs)
      comp = totalBal - histBal

      if (comp > highBal)
        highBal = comp
        context.opti_funcId = id

    if context.opti_funcId != opti_funcIdPrev
      debug "#{OPTI_TRADE_MODE_ID} = #{context.opti_funcId}"
      #Fns.debugIt traders
      if !opti_funcIdPrev? # initialize
        context.funcParams[OPTI_TRADE_MODE_ID] = [true] # gotta insert something here

  @funcInit: (id) ->
    Fns.exAs(storage.numBuys, id, 0)
    Fns.exAs(storage.numSells, id, 0)
    Fns.exAs(storage.numW, id, 0)
    Fns.exAs(storage.numL, id, 0)
    Fns.exAs(storage.maxW, id, 0)
    Fns.exAs(storage.maxL, id, 0)
    Fns.exAs(storage.assetFees, id, 0)
    Fns.exAs(storage.histBal, id, [])
    Fns.exAs(storage.currBal, id, context.currBalInit)
    Fns.exAs(storage.assetBal, id, context.assetBalInit)
    Fns.exAs(storage.totalBal, id, storage.totalBalInit)
    Fns.exAs(storage.lastBuyAmt, id, context.assetBalInit)
    Fns.exAs(storage.lastBuyPrice, id, storage.priceInit)
    Fns.exAs(storage.pendingAction, id, null)
    Fns.exAs(storage.pendingAmt, id, null)
    Fns.exAs(storage.pendingPrice, id, null)

  @funcExec: (id, func, instrument, params, priceBuy, priceSell, analyzed = null) ->
    @funcInit(id)

    if (storage.pendingAction[id] == ACTION_BUY)
      @execBuy(id, instrument, storage.pendingPrice[id])
    else if (storage.pendingAction[id] == ACTION_SELL)
      @execSell(id, instrument, storage.pendingPrice[id])

    analyze = analyzed ? MyTA.delegate(func, instrument, params)
    if analyze.halt
      if !context.warnedAnalyzeHalt then warn "analyze.halt (need the prev data to compare against)"; context.warnedAnalyzeHalt = true
      return
    if !analyze.doBuy and !analyze.doSell # nothing to see here
      return

    if analyze.doBuy
      @execBuy(id, instrument, priceBuy, true)
    else if analyze.doSell
      @execSell(id, instrument, priceSell, true)

  @execBuy: (id, instrument, price, doPending = false) ->
    isOptiTradeMode = (id == OPTI_TRADE_MODE_ID)
    doActualTrade = ((!context.opti_multi and !context.opti_variance) or isOptiTradeMode)
    doPending = doPending and !doActualTrade
    verbosePrefix = if context.opti_multi or context.opti_variance then "(#{id}) " else ""
    verbosePrefix += if doPending then "[PENDING] " else ""
#     debug "#{verbosePrefix}, #{price}, #{doPending}"

    context.buySigs++
    if !doPending and p.isPlotAdv
      plotMark
        buyAdvice: instrument.price * ADVICE_IND_MULT

    assetMaxAmtTrade = (storage.currBal[id] / price)
    if (doPending or doActualTrade) and (p.isDontBuy or (assetMaxAmtTrade < MIN_AMOUNT))
      return

    assetActualAmtTrade = @roundAsset(Math.min(p.maxAmtOrder or Number.MAX_VALUE, assetMaxAmtTrade))
    try
      success = true
      if !doActualTrade or doPending
        vMsg = "#{verbosePrefix}" + _.capitalize(ACTION_BUY) + " #{assetActualAmtTrade} * #{price}"
        if doPending
          storage.pendingAction[id] = ACTION_BUY
          storage.pendingAmt[id] = assetActualAmtTrade
          storage.pendingPrice[id] = price
#           App.die()
          if p.opti_verbose
            info vMsg + " PENDING"
          return
        else
          assetActualAmtTrade = storage.pendingAmt[id]
          storage.pendingAction[id] = null
          storage.pendingAmt[id] = null
          storage.pendingPrice[id] = null
          if (price <= _.last(instrument.low))
            if p.opti_verbose
              info vMsg + " CANCELLED"
            return # wasn't able to make trade
          if p.opti_verbose
            info vMsg + " TRADED"
      else
        success = trading.buy instrument, TRADE_TYPE_L, assetActualAmtTrade, price, p.orderTimeout
      if !success
        return

      storage.lastActionForOpti[id] = ACTION_BUY
      storage.numBuys[id]++
      #if p.opti_verbose
        #info "#{verbosePrefix}Buy #: #{storage.numBuys[id]}"

      currAmtTrade = assetActualAmtTrade * price
      storage.currBal[id] -= currAmtTrade

      assetFee = @calcFeeAsset(assetActualAmtTrade)
      storage.assetFees[id] += assetFee
      storage.assetBal[id] += assetActualAmtTrade - assetFee

      storage.lastBuyAmt[id] = assetActualAmtTrade
      storage.lastBuyPrice[id] = price
    catch e
      if /insufficient funds/i.exec e
        errorMsg = "#{verbosePrefix}Error: Insufficient Funds. assetActualAmtTrade #{assetActualAmtTrade}; price #{price}; curr needed #{assetActualAmtTrade * price}; curr avail #{storage.currBal[id]};"
        @die(errorMsg)
      else
        throw e # rethrow unhandled exception

  @execSell: (id, instrument, price, doPending = false) ->
    isOptiTradeMode = (id == OPTI_TRADE_MODE_ID)
    doActualTrade = ((!context.opti_multi and !context.opti_variance) or isOptiTradeMode)
    doPending = doPending and !doActualTrade
    verbosePrefix = if context.opti_multi or context.opti_variance then "(#{id}) " else ""
    verbosePrefix += if doPending then "[PENDING] " else ""
#     debug "#{verbosePrefix}, #{price}, #{doPending}"

    context.sellSigs++
    if !doPending and p.isPlotAdv
      plotMark
        sellAdvice: instrument.price * ADVICE_IND_MULT

    assetMaxAmtTrade = (storage.assetBal[id])
    if (doPending or doActualTrade) and (p.isDontSell or (assetMaxAmtTrade < MIN_AMOUNT))
      return

    lbpDelta = (price / storage.lastBuyPrice[id])
    if (doPending or doActualTrade)
      if (lbpDelta < p.thresholdPreventSell)
        if p.opti_verbose and !(context.opti_multi and context.opti_variance)
          debug "#{verbosePrefix}Sell Prevention; lbpDelta: #{lbpDelta.toFixed(5)}"
        return

    assetActualAmtTrade = @roundAsset(Math.min(p.maxAmtOrder or Number.MAX_VALUE, assetMaxAmtTrade))
    try
      success = true
      if !doActualTrade or doPending
        vMsg = "#{verbosePrefix}" + _.capitalize(ACTION_SELL) + " #{assetActualAmtTrade} * #{price}"
        if doPending
          storage.pendingAction[id] = ACTION_SELL
          storage.pendingAmt[id] = assetActualAmtTrade
          storage.pendingPrice[id] = price
#           App.die()
          if p.opti_verbose
            info vMsg + " PENDING"
          return
        else
          assetActualAmtTrade = storage.pendingAmt[id]
          storage.pendingAction[id] = null
          storage.pendingAmt[id] = null
          storage.pendingPrice[id] = null
          if (price >= _.last(instrument.high))
            if p.opti_verbose
              warn vMsg + " CANCELLED"
            return # wasn't able to make trade
          if p.opti_verbose
            warn vMsg + " TRADED"
      else
        success = trading.sell instrument, TRADE_TYPE_L, assetActualAmtTrade, price, p.orderTimeout
      if !success
        return

      storage.lastActionForOpti[id] = ACTION_SELL
      storage.numSells[id]++
      #if p.opti_verbose
        #warn "#{verbosePrefix}Sell #: #{storage.numSells[id]}"

      currAmtTrade = assetActualAmtTrade * price
      currAmtTrade -= @calcFeeCurr(currAmtTrade)
      storage.currBal[id] += currAmtTrade

      assetFee = @calcFeeAsset(assetActualAmtTrade)
      storage.assetFees[id] += assetFee
      storage.assetBal[id] -= assetActualAmtTrade

      lastBuyCost = (storage.lastBuyAmt[id] * storage.lastBuyPrice[id])
      storage.lastBuyAmt[id] = 0
      storage.lastBuyPrice[id] = 0

      compPL = (currAmtTrade - lastBuyCost)
      totalBal = Fns.getBalance(storage.currBal[id], storage.assetBal[id], instrument.price)
      lbpDesc = " #{@formatCurr(compPL)}"
      lbpDesc += " [(#{@formatAsset(assetActualAmtTrade, false)}*#{price}*#{(1 - context.actualFeePct)})-#{@formatCurr(lastBuyCost, false)}];"
      lbpDesc += " total P/L #{@formatCurr(totalBal - storage.totalBalInit, false)}"
      if (lbpDelta < 1)
        storage.numL[id]++
        if p.opti_verbose
          debug "#{verbosePrefix}L:#{lbpDesc}"
        if (compPL < storage.maxL[id])
          storage.maxL[id] = compPL
      else if (lbpDelta > 1)
        storage.numW[id]++
        if p.opti_verbose
          debug "#{verbosePrefix}W:#{lbpDesc}"
        if (compPL > storage.maxW[id])
          storage.maxW[id] = compPL
    catch e
      throw e # rethrow unhandled exception
#/class App

class TA
  @ADX: (high, low, close, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.ADX
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @AROON: (high, low, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, high.length - 1 - lag) # if !lag? or (lag < 1) then 0 else
    results = talib.AROON
      high: high
      low: low
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    result =
      AroonUp: _.last(results.outAroonUp)
      AroonDown: _.last(results.outAroonDown)
    result

  @BBANDS: (inReal, optInTimePeriod, optInNbDevUp, optInNbDevDn, optInMAType, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, inReal.length - 1 - lag)
    results = talib.BBANDS
      inReal: inReal
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
      optInNbDevUp: optInNbDevUp
      optInNbDevDn: optInNbDevDn
      optInMAType: optInMAType
    result =
      UpperBand: _.last(results.outRealUpperBand)
      MiddleBand: _.last(results.outRealMiddleBand)
      LowerBand: _.last(results.outRealLowerBand)
    result

  @CCI: (high, low, close, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.CCI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @DX: (high, low, close, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.DX
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @MINUS_DI: (high, low, close, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.MINUS_DI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @PLUS_DI: (high, low, close, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.PLUS_DI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @MINUS_DM: (high, low, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, high.length - 1 - lag)
    results = talib.MINUS_DM
      high: high
      low: low
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @PLUS_DM: (high, low, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, high.length - 1 - lag)
    results = talib.PLUS_DM
      high: high
      low: low
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @MA: (inReal, optInTimePeriod, optInMAType, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, inReal.length - 1 - lag)
    results = talib.MA
      inReal: inReal
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
      optInMAType: optInMAType
    # array of floats
    results

  @MACD: (inReal, optInFastPeriod, optInSlowPeriod, optInSignalPeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, inReal.length - 1 - lag)
    results = talib.MACD
      inReal: inReal
      startIdx: 0
      endIdx: endIdx
      optInFastPeriod: optInFastPeriod
      optInSlowPeriod: optInSlowPeriod
      optInSignalPeriod: optInSignalPeriod
    result =
      MACD: _.last(results.outMACD)
      MACDSignal: _.last(results.outMACDSignal)
      MACDHist: _.last(results.outMACDHist)
    result

  @MFI: (high, low, close, volume, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
    results = talib.MFI
      high: high
      low: low
      close: close
      volume: volume
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    # array of floats
    _.last(results)

  @RSI: (inReal, optInTimePeriod, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, inReal.length - 1 - lag)
    results = talib.RSI
      inReal: inReal
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
    _.last(results)

  @STOCH: (high, low, close, optInFastK_Period, optInSlowK_Period, optInSlowK_MAType, optInSlowD_Period, optInSlowD_MAType, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, close.length - 1 - lag)
#     debug "STOCH: close.length: #{close.length}"
#     debug "STOCH: endIdx: #{endIdx}"
    results = talib.STOCH
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: endIdx
      optInFastK_Period: optInFastK_Period
      optInSlowK_Period: optInSlowK_Period
      optInSlowK_MAType: optInSlowK_MAType
      optInSlowD_Period: optInSlowD_Period
      optInSlowD_MAType: optInSlowD_MAType
    result =
      SlowK: _.last(results.outSlowK)
      SlowD: _.last(results.outSlowD)
    result

  @STOCHRSI: (inReal, optInTimePeriod, optInFastK_Period, optInFastD_Period, optInFastD_MAType, lag = null) ->
    lag ?= p.lag
    endIdx = Math.max(0, inReal.length - 1 - lag)
#     debug "STOCHRSI: inReal.length: #{inReal.length}"
#     debug "STOCHRSI: endIdx: #{endIdx}"
    results = talib.STOCHRSI
      inReal: inReal
      startIdx: 0
      endIdx: endIdx
      optInTimePeriod: optInTimePeriod
      optInFastK_Period: optInFastK_Period
      optInFastD_Period: optInFastD_Period
      optInFastD_MAType: optInFastD_MAType
    result =
      FastK: _.last(results.outFastK)
      FastD: _.last(results.outFastD)
    result
#/class TA

class MyTA
  @delegate: (func, instrument, params) ->
    ans = {
      halt: null,
      doBuy: null,
      doSell: null,
    }
    funcHandle = switch func
      when "AROON" then @AROON
      when "BBANDS" then @BBANDS
      when "CCI" then @CCI
      when "DX" then @DX
      when "MA" then @MA
      when "MACD" then @MACD
      when "MFI" then @MFI
      when "RSI" then @RSI
      when "STOCH" then @STOCH
      when "STOCHRSI" then @STOCHRSI
      else App.die("Invalid argument (#{func}) in delegate " + arguments.callee.name)
    funcHandle(instrument, params, ans)
    return ans

  @getFuncId: (func, params) ->
    if !context.opti_variance
      return func

    ans = "#{func};"
    for k, v of params
      ans += "#{k}:#{v};"

    return ans

  @getParams: (func) ->
    params = switch func
      when "AROON" then { TimePeriod: p.AROON_optInTimePeriod }
      when "BBANDS" then { TimePeriod: p.BBANDS_optInTimePeriod, NbDevUp: p.BBANDS_optInNbDevUp, NbDevDn: p.BBANDS_optInNbDevDn, MAType: p.BBANDS_optInMAType }
      when "CCI" then { TimePeriod: p.CCI_optInTimePeriod }
      when "DX" then { TimePeriod: p.DX_optInTimePeriod }
      when "MA" then { TimePeriodShort: p.MA_optInTimePeriodShort, TimePeriodLong: p.MA_optInTimePeriodLong, MAType: p.MA_optInMAType }
      when "MACD" then { FastPeriod: p.MACD_optInFastPeriod, SlowPeriod: p.MACD_optInSlowPeriod, SignalPeriod: p.MACD_optInSignalPeriod }
      when "MFI" then { TimePeriod: p.MFI_optInTimePeriod }
      when "RSI" then { TimePeriod: p.RSI_optInTimePeriod }
      when "STOCH" then { FastK_Period: p.STOCH_optInFastK_Period, SlowK_Period: p.STOCH_optInSlowK_Period, SlowK_MAType: p.STOCH_optInSlowK_MAType, SlowD_Period: p.STOCH_optInSlowD_Period, SlowD_MAType: p.STOCH_optInSlowD_MAType }
      when "STOCHRSI" then { TimePeriod: p.STOCHRSI_optInTimePeriod, FastK_Period: p.STOCHRSI_optInFastK_Period, FastD_Period: p.STOCHRSI_optInFastD_Period, FastD_MAType: p.STOCHRSI_optInFastD_MAType }
      else App.die("Invalid argument (#{func}) in getParams " + arguments.callee.name)

    ans = {}
    id = MyTA.getFuncId(func, params)
    ans[id] = params # default version
  #   if !context.opti_variance
  #     return ans

    if context.opti_variAmtExists
      for theId, theParams of ans
        for k, v of theParams
          do (k, v) -> # like an anon func
            if k.includes("MAType") or (v != Math.round(v))
              return
            for i in [1..p.opti_variAmt]
              vSqrt = Math.pow(v, 1 / (i + 1))
              for j, z in [-vSqrt, vSqrt]
                paramsCopy = _.cloneDeep(theParams)
                if _.isEmpty(paramsCopy)
                  App.die("Failed copy (k:#{k},i:#{i},j:#{j}) in getParams " + arguments.callee.name)
                paramsCopy[k] = Fns.roundTo(Number(v) + Number(j), 2, 0)
                id = MyTA.getFuncId(func, paramsCopy)
                ans[id] = paramsCopy

    if p.opti_variMA
      allMATypes = optInMATypeOptsKeys
      for theId, theParams of ans
        for k, v of theParams
          do (k, v) -> # like an anon func
            if !k.includes("MAType")
              return
            newMATypes = _.without(allMATypes, v)
            for i in newMATypes
              paramsCopy = _.cloneDeep(theParams)
              if _.isEmpty(paramsCopy)
                App.die("Failed copy (k:#{k},i:#{i}) in getParams " + arguments.callee.name)
              paramsCopy[k] = i
              id = MyTA.getFuncId(func, paramsCopy)
              ans[id] = paramsCopy

    return ans

  @AROON: (instrument, params, ans) ->
    results = TA.AROON(instrument.high, instrument.low, params.TimePeriod)
    diff = results.AroonUp - results.AroonDown
    #debug diff

  #   plot
  #     AROON: diff

    if (diff > p.AROON_thresholdDiff)
      ans.doBuy = true
    else if (diff < p.AROON_thresholdDiff)
      ans.doSell = true

  @BBANDS: (instrument, params, ans) ->
    results = TA.BBANDS(instrument.close, params.TimePeriod, params.NbDevUp, params.NbDevDn, params.MAType)

    plot
      BBANDS_UpperBand: results.UpperBand
      BBANDS_MiddleBand: results.MiddleBand
      BBANDS_LowerBand: results.LowerBand

    if (instrument.price > results.UpperBand)
      ans.doSell = true
    else if (instrument.price < results.LowerBand)
      ans.doBuy = true

  @CCI: (instrument, params, ans) ->
    results = TA.CCI(instrument.high, instrument.low, instrument.close, params.TimePeriod)
    #debug results

  #   plot
  #     CCI: results

    if results >= p.CCI_thresholdUpper
      ans.doBuy = true
    else if results <= p.CCI_thresholdLower
      ans.doSell = true

  @DX: (instrument, params, ans) ->
    results = TA.DX(instrument.high, instrument.low, instrument.close, params.TimePeriod)
#     id = MyTA.getFuncId("DX", params)
#     debug "#{id}: #{results}"

  #   plot
  #     DX: results

    if results >= p.DX_threshold
      resultsMinus = TA.MINUS_DI(instrument.high, instrument.low, instrument.close, params.TimePeriod)
      resultsPlus = TA.PLUS_DI(instrument.high, instrument.low, instrument.close, params.TimePeriod)
      if (resultsPlus > resultsMinus)
        ans.doBuy = true
      else if (resultsPlus < resultsMinus)
        ans.doSell = true
      else
        ans.doNothing = true
    else
      ans.doNothing = true

  @MA: (instrument, params, ans) ->
    short = TA.MA(instrument.close, params.TimePeriodShort, params.MAType)
    shortOld = short[short.length - 2]
    shortNew = short[short.length - 1]

    long = TA.MA(instrument.close, params.TimePeriodLong, params.MAType)
    longOld = long[long.length - 2]
    longNew = long[long.length - 1]

    if p.isPlotShort
      plot
        MA_short: shortNew
    if p.isPlotLong
      plot
        MA_long: longNew

    if !shortOld or !longOld
      ans.halt = true
      return

    diff = Fns.diff(shortNew, longNew)
    if p.isDebugDiff
      debug "Diff: #{diff}"

    if (shortOld >= longOld) and (shortNew < longNew) and (diff < -p.MA_thresholdSell)
      ans.doSell = true
    else if (shortOld <= longOld) and (shortNew > longNew) and (diff > p.MA_thresholdBuy)
      ans.doBuy = true

  @MACD: (instrument, params, ans) ->
    results = TA.MACD(instrument.close, params.FastPeriod, params.SlowPeriod, params.SignalPeriod)

    plot
      MACD_MACD: results.MACD + instrument.price
      MACD_MACDSignal: results.MACDSignal + instrument.price
      MACD_MACDHist: results.MACDHist + instrument.price

    if (results.MACD > results.MACDSignal)
      ans.doBuy = true
    else if (results.MACD < results.MACDSignal)
      ans.doSell = true

  @MFI: (instrument, params, ans) ->
    results = TA.MFI(instrument.high, instrument.low, instrument.close, instrument.volumes, params.TimePeriod)
    #debug results

  #   plot
  #     MFI: results

    if (results < p.MFI_thresholdUpper)
      ans.doBuy = true
    else if (results > p.MFI_thresholdLower)
      ans.doSell = true

  @RSI: (instrument, params, ans) ->
    results = TA.RSI(instrument.close, params.TimePeriod)

#     id = MyTA.getFuncId("RSI", params)
#     debug "#{id}: #{results}"

    if (results <= p.RSI_thresholdLower)
      ans.doBuy = true
    else if (results >= p.RSI_thresholdUpper)
      ans.doSell = true
    else
      ans.doNothing = true

#     if context.last_RSI_result and (results < context.last_RSI_result)
#       ans.doBuy = true
#     else if context.last_RSI_result and (results > context.last_RSI_result)
#       ans.doSell = true
#
#     context.last_RSI_result = results

  @STOCH: (instrument, params, ans) ->
    results = TA.STOCH(instrument.high, instrument.low, instrument.close, params.FastK_Period, params.SlowK_Period, params.SlowK_MAType, params.SlowD_Period, params.SlowD_MAType)
    #debug results

#     plot
#       STOCH_SlowK: results.SlowK
#       STOCH_SlowD: results.SlowD

#     id = MyTA.getFuncId("STOCH", params)
#     debug "#{id}: SlowK: #{results.SlowK}"
#     debug "#{id}: SlowD: #{results.SlowD}"

#     result = results.SlowD
#     if !Fns.isSet(result)
#       return
    resultMax = Math.max(results.SlowK, results.SlowD)
    resultMin = Math.min(results.SlowK, results.SlowD)

    v = 1

    if (v == 1)
      context.last_STOCH_activatedLower ?= false
      context.last_STOCH_activatedUpper ?= false
      if (resultMin <= p.STOCH_thresholdLower)
        context.last_STOCH_activatedLower = true
        context.last_STOCH_activatedUpper = false
      else if (resultMax >= p.STOCH_thresholdUpper)
        context.last_STOCH_activatedUpper = true
        context.last_STOCH_activatedLower = false
      else
        if context.last_STOCH_activatedLower
          context.last_STOCH_activatedLower = false
          ans.doBuy = true
        else if context.last_STOCH_activatedUpper
          context.last_STOCH_activatedUpper = false
          ans.doSell = true
        else
          ans.doNothing = true
    else if (v == 2)
      if (results.SlowK > results.SlowD)
        ans.doBuy = true
      else if (results.SlowK < results.SlowD)
        ans.doSell = true
      else
        ans.doNothing = true

# https://rpubs.com/tterryt2/ebt_pt5#process-for-stochrsi
  @STOCHRSI: (instrument, params, ans) ->
#     debug "STOCHRSI: TimePeriod = #{params.TimePeriod}; FastK_Period = #{params.FastK_Period}; FastD_Period = #{params.FastD_Period}; FastD_MAType = #{p.STOCHRSI_optInFastD_MAType}"
#     debug "STOCHRSI (toInt): TimePeriod = #{Fns.toInt(params.TimePeriod)}; FastK_Period = #{Fns.toInt(params.FastK_Period)}; FastD_Period = #{Fns.toInt(params.FastD_Period)}; FastD_MAType = #{Fns.toInt(p.STOCHRSI_optInFastD_MAType)}"
#     return

    results = TA.STOCHRSI(instrument.close, params.TimePeriod, params.FastK_Period, params.FastD_Period, params.FastD_MAType)

#     plot
#       STOCHRSI_FastK: results.FastK
#       STOCHRSI_FastD: results.FastD

#     id = MyTA.getFuncId("STOCHRSI", params)
#     debug "#{id}: FastK: #{results.FastK}"
#     debug "#{id}: FastD: #{results.FastD}"

    result = results.FastD
    if !Fns.isSet(result)
      return

    openVal = _.last(instrument.open)
    closeVal = _.last(instrument.close)
    isLong = (closeVal > openVal)
    isShort = (closeVal < openVal)
#     if true
#       isLong = !isLong
#       isShort = !isShort

    if (result >= p.STOCHRSI_thresholdLower)
      ans.doBuy = true
#       if isLong
#         ans.doBuy = true
#       else if isShort
#         ans.doSell = true
    else if (result <= p.STOCHRSI_thresholdUpper)
      ans.doSell = true
#       if isLong
#         ans.doSell = true
#       else if isShort
#         ans.doBuy = true
    else
      ans.doNothing = true

  @NONE: (instrument, params, ans) ->
    ans.halt = true
#/class MyTA

# PARAMS
pm = {} # params meta {(t)itle, (d)efaultValue, [(o)ptions], [(m)ore]}
pm.configFee = { t: "Config: Trading fee (%)", d: configFeeDef, m: " (same value from config screen)" }
pm.makerBufferCurr = { t: "Maker trade buffer ($)", d: ".01" }
pm.makerBufferMult = { t: "Maker trade buffer (multiplier)", d: .001, m: " (only if above is 0)" }
pm.opti_header = { t: "▼ Opti", d: false }
pm.lag = { t: "Lag", d: LAG_DEF, m: " (>= 0)" }
pm.opti_funcList = { t: "TAlib Function List", d: FUNC_LIST_DEF, m: (" (comma-separated list of TAlib functions to use [" + talibFuncOpts.join() + "]; '#{FUNC_LIST_ALL}' = use all)") }
pm.opti_funcSolo = { o: [FUNC_SOLO_ALL].concat(talibFuncOpts), t: "TAlib Function Solo", d: FUNC_SOLO_DEF, m: " (leave default '#{FUNC_SOLO_ALL}' to use above TAlib Function List)" }
pm.opti_variAmt = { t: "Variance", d: 1, m: " (vary certain params up/down this many times; 0 = disable, too high = timeout)" }
pm.opti_variMA = { t: "Vary MA?", d: true, m: " (use all MA modes as variants [only when applicable])" }
pm.opti_combo = { t: "Combo Decider?", d: false, m: " (use all variants to make trade decisions)" }
pm.opti_trade = { t: "Run Optibot?", d: true, m: " (actually make trades in multivar-mode [aka non-solo and/or variance mode])" }
pm.opti_historyVs = { t: "History Vs.", d: Fns.interval2historyVsOpti(@config.interval), m: " (how many recent ticks to analyze for func-vs-func switch; 0 = disable [i.e. all])" }
pm.opti_verbose = { t: "Verbose?", d: false, m: " (output everything)" }
pm.AROON_header = { t: "▼ TAlib: AROON", d: false }
pm.AROON_thresholdDiff = { t: "AROON: Diff Threshold", d: 33, m: " (0 = disable)" }
pm.AROON_optInTimePeriod = { t: "AROON: Period", d: PERIOD_DEF } # 24
pm.BBANDS_header = { t: "▼ TAlib: BBANDS", d: false }
pm.BBANDS_optInTimePeriod = { t: "BBANDS: Period", d: PERIOD_DEF } # 21
pm.BBANDS_optInNbDevUp = { t: "BBANDS: NbDevUp", d: 2.75 } # experiment w/ value: 1
pm.BBANDS_optInNbDevDn = { t: "BBANDS: NbDevDn", d: 2.75 }
pm.BBANDS_optInMAType = { o: optInMATypeOptsKeys, t: "BBANDS: MA Type", d: optInMATypeDef, m: (" - " + optInMATypeMore) }
pm.CCI_header = { t: "▼ TAlib: CCI", d: false }
pm.CCI_thresholdUpper = { t: "CCI: Upper Threshold", d: 100 }
pm.CCI_thresholdLower = { t: "CCI: Lower Threshold", d: -100 }
pm.CCI_optInTimePeriod = { t: "CCI: Period", d: PERIOD_DEF } # 20
pm.DX_header = { t: "▼ TAlib: DX", d: false }
pm.DX_threshold = { t: "DX: Threshold", d: 10 }
pm.DX_optInTimePeriod = { t: "DX: Period", d: PERIOD_DEF } # 20
pm.MA_header = { t: "▼ TAlib: MA", d: false }
pm.MA_optInTimePeriodShort = { t: "MA: Period: Short", d: 10 } # 10
pm.MA_optInTimePeriodLong = { t: "MA: Period: Long", d: 21 } # 21
pm.MA_optInMAType = { o: optInMATypeOptsKeys, t: "MA: MA Type", d: optInMATypeDef, m: (" - " + optInMATypeMore) }
pm.MA_thresholdBuy = { t: "MA: Buy Threshold", d: .02, m: " (0 = disable)" }
pm.MA_thresholdSell = { t: "MA: Sell Threshold", d: .005, m: " (0 = disable)" }
pm.MACD_header = { t: "▼ TAlib: MACD", d: false }
pm.MACD_optInFastPeriod = { t: "MACD: Fast Period", d: 12 }
pm.MACD_optInSlowPeriod = { t: "MACD: Slow Period", d: 26 }
pm.MACD_optInSignalPeriod = { t: "MACD: Signal Period", d: 9 }
pm.MFI_header = { t: "▼ TAlib: MFI", d: false }
pm.MFI_thresholdUpper = { t: "MFI: Upper Threshold", d: 70, m: " (0 = disable)" }
pm.MFI_thresholdLower = { t: "MFI: Lower Threshold", d: 30, m: " (0 = disable)" }
pm.MFI_optInTimePeriod = { t: "MFI: Period", d: PERIOD_DEF } # 24
pm.RSI_header = { t: "▼ TAlib: RSI", d: false }
pm.RSI_thresholdUpper = { t: "RSI: Upper Threshold", d: 70 }
pm.RSI_thresholdLower = { t: "RSI: Lower Threshold", d: 30 }
pm.RSI_optInTimePeriod = { t: "RSI: Period", d: PERIOD_DEF } # 14
pm.STOCH_header = { t: "▼ TAlib: STOCH", d: false }
pm.STOCH_thresholdUpper = { t: "STOCH: Upper Threshold", d: 80 }
pm.STOCH_thresholdLower = { t: "STOCH: Lower Threshold", d: 20 }
pm.STOCH_optInFastK_Period = { t: "STOCH: FastK Period", d: 21 }
pm.STOCH_optInSlowK_Period = { t: "STOCH: SlowK Period", d: 10 } # 3
pm.STOCH_optInSlowK_MAType = { o: optInMATypeOptsKeys, t: "STOCH: SlowK MA Type", d: optInMATypeDef, m: (" - " + optInMATypeMore) }
pm.STOCH_optInSlowD_Period = { t: "STOCH: SlowD Period", d: 10 } # 3
pm.STOCH_optInSlowD_MAType = { o: optInMATypeOptsKeys, t: "STOCH: SlowD MA Type", d: optInMATypeDef, m: (" - " + optInMATypeMore) }
pm.STOCHRSI_header = { t: "▼ TAlib: STOCHRSI", d: false }
pm.STOCHRSI_thresholdUpper = { t: "STOCHRSI: Upper Threshold", d: 80 }
pm.STOCHRSI_thresholdLower = { t: "STOCHRSI: Lower Threshold", d: 20 }
pm.STOCHRSI_optInTimePeriod = { t: "STOCHRSI: Period", d: PERIOD_DEF } # 14
pm.STOCHRSI_optInFastK_Period = { t: "STOCHRSI: FastK Period", d: 3 }
pm.STOCHRSI_optInFastD_Period = { t: "STOCHRSI: FastD Period", d: 1.27 } # 3, 1.27
pm.STOCHRSI_optInFastD_MAType = { o: optInMATypeOptsKeys, t: "STOCHRSI: FastD MA Type", d: optInMATypeDef, m: (" - " + optInMATypeMore) }
pm.misc_header = { t: "▼ Misc", d: false }
pm.thresholdPreventSell = { t: "Sell Prevention Ratio", d: .75, m: " (P/L ratio below which not to sell; 0 = disable, 1 = never sell at loss)" } # prev: .975
pm.maxAmtOrder = { t: "Max asset amount per order", d: 0, m: " (0 = disable)" }
pm.isDontBuy = { t: "Don't execute long (buy)?", d: false }
pm.isDontSell = { t: "Don't execute short (sell)?", d: false }
pm.orderTimeout = { t: "Order timeout (s)", d: ((@config.interval * 60) - 5) }
pm.isPlotShort = { t: "Plot short trend line", d: true }
pm.isPlotLong = { t: "Plot long trend line", d: true }
pm.isPlotAdv = { t: "Plot buy/sell advice", d: true }
pm.isPreload = { t: "Attempt preload?", d: false, m: " (Pro+ only)" }
pm.isPrintSettings = { t: "Print settings on start?", d: true }
pm.isDebugDiff = { t: "Debug diff?", d: false }

p = {} # params answers object
for k, v of pm
  if !v
    continue
  tm = (v.t + (v.m ? ""))
  if v.o
    p[k] = params.addOptions tm, v.o, ("" + v.d)
  else
    p[k] = params.add tm, v.d

# MAIN FUNCTIONS
#This runs once when the bot is started
init: (context) ->
  setPlotOptions
    short:
      color: "yellow"
    long:
      color: "blue"
    sellAdvice:
      color: "red"
      lineWidth: 0.1
      #secondary: true
    buyAdvice:
      color: "green"
      lineWidth: 0.1
      #secondary: true
    sell:
      color: "orange"
      #secondary: true
    buy:
      color: "lime"
      #secondary: true

  context.opti_multi = (p.opti_funcSolo == FUNC_SOLO_ALL)
  context.opti_variAmtExists = (p.opti_variAmt >= 1)
  context.opti_variance = context.opti_variAmtExists or p.opti_variMA
  if !context.opti_multi and !context.opti_variance
    p.opti_trade = false
    p.opti_historyVs = null
  if !p.opti_historyVs
    p.opti_historyVs = null

  #Fns.debugIt @config
  storage.numTicks = 0
  storage.numBuys = {}
  storage.numSells = {}
  storage.numW = {}
  storage.numL = {}
  storage.maxW = {}
  storage.maxL = {}
  storage.assetFees = {}
  storage.histBal = {}
  storage.currBal = {}
  storage.assetBal = {}
  storage.totalBal = {}
  storage.lastBuyAmt = {}
  storage.lastBuyPrice = {}
  storage.lastActionForOpti = {}
  storage.pendingAction = {}
  storage.pendingAmt = {}
  storage.pendingPrice = {}

  #portMarket = _.keys(@portfolios)[0]
  #Fns.debugIt @portfolios[portMarket].positions.usd; App.stopHard()
  #portInsArr = _.keys(@portfolios[portMarket].positions)
  #portIns1 = portInsArr[0]
  #portIns2 = portInsArr[1]

  context.actualFeePct = (p.configFee / 100)
  context.configPeriod = Fns.interval2period(@config.interval)
  #warn "period: " + context.configPeriod
  if p.isPreload and context.configPeriod
    debug @config.market + " " + @config.pair + " " + context.configPeriod
    ds.add @config.market, @config.pair, context.configPeriod
    ticks = ds.get @config.market, @config.pair, context.configPeriod
    ticker = trading.getTicker ticks
    Fns.debugIt ticker
    context.preloadPrice = ticker.buy
    debug "Preloaded price: (#{context.preloadPrice})"

#This runs once every tick or bar on the graph
handle: (context, data, storage) ->
  if !context.isPrintSettingsDone and p.isPrintSettings then Fns.doPrintSettings(pm, p); context.isPrintSettingsDone = true

  storage.botStartedAt ?= data.at
  instrument = data.instruments[0]
  #debug "Current price: #{instrument.price}"
  if !instrument.price
    if !context.warnedMissingInsPrice then warn "ERROR: instrument.price undefined"; context.warnedMissingInsPrice = true
    return
    #stop()

  ticker = trading.getTicker instrument
  storage.numTicks++
  context.assetUp ?=  instrument.asset().toUpperCase()
  context.assetIsFiat ?=  (symbolsFiat.indexOf(context.assetUp) > -1)
  context.assetDecLen ?= (if context.assetIsFiat then FIXED_LEN_F else FIXED_LEN_A)
  context.currUp ?=  instrument.curr().toUpperCase()
  context.currIsFiat ?=  (symbolsFiat.indexOf(context.currUp) > -1)
  context.currDecLen ?= (if context.currIsFiat then FIXED_LEN_F else FIXED_LEN_A)
  context.assetBalInit ?= App.getAmount(instrument, INS_TYPE_A)
  context.currBalInit ?= App.getAmount(instrument, INS_TYPE_C)

  context.funcParams ?= {}
  context.funcMap ?= {}

  if !storage.priceInit?
    if context.preloadPrice
      debug "Preloaded price found for #{instrument.asset()}"
    storage.priceInit = (context.preloadPrice ? _.last(instrument.open))
    debug "Initial price: #{App.formatCurr(storage.priceInit)}"

  if !storage.totalBalInit?
    storage.totalBalInit = Fns.getBalance(context.currBalInit, context.assetBalInit, storage.priceInit)
    debug "Initial balance: #{App.formatCurr(storage.totalBalInit)}"
    info "======= STARTING ======="

  priceBuy = priceBuyMkt = ticker.buy
  priceSell = priceSellMkt = ticker.sell
#   priceBuy = priceBuyMkt = priceSell = priceSellMkt = instrument.price

  p.makerBufferCurr = Number(p.makerBufferCurr)
  priceBuy = (priceBuyMkt - p.makerBufferCurr)
  priceSell = (priceSellMkt + p.makerBufferCurr)
  if !p.makerBufferCurr and p.makerBufferMult
    priceBuy = (priceBuyMkt * (1 - p.makerBufferMult))
    priceSell = (priceSellMkt * (1 + p.makerBufferMult))

  if context.currIsFiat # only trim fixed for lame fiat
    priceBuy = App.roundCurr(priceBuy, 1)
    priceSell = App.roundCurr(priceSell, 1)

  context.funcs ?=
    if !context.opti_multi then [p.opti_funcSolo]
    else if (p.opti_funcList == FUNC_LIST_ALL) then talibFuncOpts
    else p.opti_funcList.split(",")

  context.buySigs = context.sellSigs = 0

  for func in context.funcs
    context.funcParams[func] ?= MyTA.getParams(func)
    for id, params of context.funcParams[func]
      context.funcMap[id] ?= func
      App.funcExec(id, func, instrument, params, priceBuy, priceSell)

  funcMapKeys = _.keys(context.funcMap)
  if !context.opti_funcId? and (funcMapKeys.length == 1)
    context.opti_funcId = _.first(funcMapKeys)
    info "context.opti_funcId solo set: #{context.opti_funcId}"

  if p.opti_trade
    App.checkOptiTrade(instrument) # gotta check every time after other algs
    if context.opti_funcId?
      if !context.warnedOptiTradeMode then info "isOptiTradeMode!"; context.warnedOptiTradeMode = true

      analyzed = null
      if p.opti_combo
        if p.opti_verbose
          debug "buySigs: #{context.buySigs}. sellSigs: #{context.sellSigs}."
        if (context.buySigs > context.sellSigs)
          analyzed = { doBuy: true }
        if (context.buySigs < context.sellSigs)
          analyzed = { doSell: true }
      else
        if (storage.lastActionForOpti[context.opti_funcId] == ACTION_BUY)
          analyzed = { doBuy: true }
        if (storage.lastActionForOpti[context.opti_funcId] == ACTION_SELL)
          analyzed = { doSell: true }
        storage.lastActionForOpti[context.opti_funcId] = null

      func = context.funcMap[context.opti_funcId]
      params = context.funcParams[func][context.opti_funcId]
      App.funcExec(OPTI_TRADE_MODE_ID, func, instrument, params, priceBuy, priceSell, analyzed)

onRestart: ->
  debug "Bot restarted at #{new Date(data.at)}"

onStop: ->
  if context.stopHard
    return
  instrument = data.instruments[0]
  warn "======= STOPPING ======="
  warn "Bot started at #{new Date(storage.botStartedAt)}"
  warn "Bot stopped at #{new Date(data.at)}"
  debug "Final price: #{App.formatCurr(instrument.price)} (Initial: #{App.formatCurr(storage.priceInit)})"

  gainPctMkt = Fns.getIncreasePct(storage.priceInit, instrument.price)
  rankings = []
  rankings.push({ f: "*** Market/B&H", p: gainPctMkt })
  context.funcs?.push(OPTI_TRADE_MODE_ID) # add to end
  for func in context.funcs
    isOptiTradeMode = (func == OPTI_TRADE_MODE_ID)
    for fid, params of context.funcParams[func]
      id = if isOptiTradeMode then func else fid
      debug "======= id: #{id} ======="
      assetRemVal = instrument.price * storage.assetBal[id]
      lastBuyCost = if !storage.numBuys[id] then 0 else (storage.lastBuyAmt[id] * storage.lastBuyPrice[id])
      compPL = (assetRemVal - lastBuyCost)
#       storage.totalBal[id] += compPL
      storage.lastBuyAmt[id] = 0
      storage.lastBuyPrice[id] = 0
      totalBal = Fns.getBalance(storage.currBal[id], storage.assetBal[id], instrument.price)
      #Fns.assert((storage.totalBal[id] == (assetRemVal + storage.currBal[id])), "storage.totalBal[id] != assetRemVal + storage.currBal[id])")

      if isOptiTradeMode
        assetBalFinal = App.getAmount(instrument, INS_TYPE_A)
        currBalFinal = App.getAmount(instrument, INS_TYPE_C)
        totalBalFinal = Fns.getBalance(currBalFinal, assetBalFinal, instrument.price)
        totalBalA = App.roundCurr(totalBal)
        totalBalB = App.roundCurr(totalBalFinal)
        totalBalDiff = App.roundCurr(Math.abs(totalBalA - totalBalB))
        Fns.assert((totalBalDiff <= .01), "#{OPTI_TRADE_MODE_ID}: totalBal (#{totalBalA}) vs totalBalFinal (#{totalBalB}) diff must be <= .01 but was (#{totalBalDiff})")

      debug "Final balance: #{App.formatCurr(totalBal)} (Initial: #{App.formatCurr(storage.totalBalInit)})"
      debug "Total fees: #{App.formatAsset(storage.assetFees[id])} (#{App.formatCurr(storage.assetFees[id] * instrument.price)})"

      gainPctBot = Fns.getIncreasePct(storage.totalBalInit, totalBal)
      gainPctDiff = gainPctBot - gainPctMkt
      Fns.printNumeric gainPctDiff, "Bot: #{Fns.formatPct(gainPctBot)} vs Market: #{Fns.formatPct(gainPctMkt)} (spread: #{Fns.formatPct(gainPctDiff)})"
      rankings.push({ f: id, p: gainPctBot })
      debug "W-L: #{storage.numW[id]}-#{storage.numL[id]}. Max W: +#{App.formatCurr(storage.maxW[id])}. Max L: #{App.formatCurr(storage.maxL[id])}."

  if context.opti_multi or context.opti_variance
    rankings.sort((a, b) -> b.p - a.p)
    warn "======= RANKINGS ======="
    for v, i in rankings
      gainPctDiff = v.p - gainPctMkt
      rankingsStr = "#{i+1}. #{v.f} [#{Fns.formatPct(v.p)}]"
      Fns.printNumeric gainPctDiff, rankingsStr

  debug "/"
  debug "/"
  debug "/"

#REF:
#https://cryptotrader.org/talib
#https://cryptotrader.org/api
#https://cryptotrader.org/topics/328783/getting-started
#https://cryptotrader.org/topics/195631/api2-upcoming-changes-new-module-preview

#TODO LATER:
#sequential orders bot
#Janus Bot 1.0 by Invictus (Thanasis full working framework) https://cryptotrader.org/backtests/WsXwC7nQ87fcRKSFd
#https://cryptotrader.org/topics/928104/placing-trades-the-weak-link-in-the-current-bots
#close position on stop
#trailing stop-loss
#period-/exchange-/pair-optimized settings
#compare backtests against other popular bots
#check out Tweakaholic/Hypertune/Trendatron/etc more
#BBANDS https://cryptotrader.org/topics/056547/appropriate-use-of-bollinger-bands-and-other-talib-functions
#https://cryptotrader.org/topics/870242/insufficient-funds-error
#BFX Margin Slayer MasterCode by tweakaholic https://cryptotrader.org/strategies/wCQnKeGmuh3CgvCRX
#Ice Whale by pulsecat https://cryptotrader.org/strategies/nk5DQY7J8bjXtfE3N
#Grinny's Simple MACD-EMA Trading bot https://cryptotrader.org/backtests/isgLbZBaavSiipgev
#Aspiramedia Megathread - Indicators/Frameworks/Bots - All Free https://cryptotrader.org/topics/121656/aspiramedia-megathread-indicators-frameworks-bots-all-free

#TODO NOW:
#default optimal historyVs on interval
#add'l algs
#use historical data/book right at start if possible?
#use TI/MA from https://www.investing.com/currencies/btc-usd-technical?cid=1010796
