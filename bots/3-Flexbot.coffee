# Flexbot

# MODULES
params = require "params"
talib = require "talib"
trading = require "trading"
#ds  = require "datasources" #Pro+ only

# CONSTS
GLOBAL = @ # for reference in classes
DO_NONES = false
MATYPE_DEF = 0
NBDEV_DEF = 3
MIN_AMOUNT_ASSET = .01
MIN_AMOUNT_CURR = 10
TRADE_PM_DEF = .01
UNSET_DEF = "-999"
ACTION_BUY = "buy"
ACTION_SELL = "sell"
ACTION_NONE = "none"
DEFS = {
  "DEF": {
    "period": "14",
    "lag": "1",
  },
  "1m": {
    "period": "120", # 73
    "lag": "10", # 120, 60, 10
  },
  "1h": {
    "period": "24",
    "lag": "6",
  },
  "1d": {
    "period": "3",
  },
}

class TA
  @accbands: (high, low, close, lag, period) ->
    results = talib.ACCBANDS
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    result =
      UpperBand: _.last(results.outRealUpperBand)
      MiddleBand: _.last(results.outRealMiddleBand)
      LowerBand: _.last(results.outRealLowerBand)
    result

  @ad: (high, low, close, volume, lag, period) ->
    results = talib.AD
      high: high
      low: low
      close: close
      volume: volume
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @adosc: (high, low, close, volume, lag, FastPeriod, SlowPeriod) ->
    results = talib.ADOSC
      high: high
      low: low
      close: close
      volume: volume
      startIdx: 0
      endIdx: high.length - lag
      optInFastPeriod: FastPeriod
      optInSlowPeriod: SlowPeriod
    _.last(results)

  @adx: (high, low, close, lag, period) ->
    results = talib.ADX
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @adxr: (high, low, close, lag, period) ->
    results = talib.ADXR
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @apo: (data, lag, FastPeriod, SlowPeriod, MAType) ->
    results = talib.APO
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInFastPeriod: FastPeriod
      optInSlowPeriod: SlowPeriod
      optInMAType: MAType
    _.last(results)

  @aroon: (high, low, lag, period) ->
    results = talib.AROON
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    result =
      up: _.last(results.outAroonUp)
      down: _.last(results.outAroonDown)
    result

  @aroonosc: (high, low, lag, period) ->
    results = talib.AROONOSC
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @atr: (high, low, close, lag, period) ->
    results = talib.ATR
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @avgprice: (open, high, low, close, lag, period) ->
    results = talib.AVGPRICE
      open: open
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: open.length - lag
      optInTimePeriod: period
    _.last(results)

  @bbands: (data, period, lag, NbDevUp, NbDevDn, MAType) ->
    results = talib.BBANDS
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInNbDevUp: NbDevUp
      optInNbDevDn: NbDevDn
      optInMAType: MAType
    result =
      UpperBand: _.last(results.outRealUpperBand)
      MiddleBand: _.last(results.outRealMiddleBand)
      LowerBand: _.last(results.outRealLowerBand)
    result

  @beta: (data_0, data_1, lag, period) ->
    results = talib.BETA
      inReal0: data_0
      inReal1: data_1
      startIdx: 0
      endIdx: data_0.length - lag
      optInTimePeriod: period
    _.last(results)

  @bop: (open, high, low, close, lag) ->
    results = talib.BOP
      open: open
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
    _.last(results)

  @cci: (high, low, close, lag, period) ->
    results = talib.CCI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @cmo: (data, lag, period) ->
    results = talib.CMO
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @correl: (data_0, data_1, lag, period) ->
    results = talib.CORREL
      inReal0: data_0
      inReal1: data_1
      startIdx: 0
      endIdx: data_0.length - lag
      optInTimePeriod: period
    _.last(results)

  @dema: (data, lag, period) ->
    results = talib.DEMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @dx: (high, low, close, lag, period) ->
    results = talib.DX
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @ema: (data, lag, period) ->
    results = talib.EMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @ht_dcperiod: (data, lag) ->
    results = talib.HT_DCPERIOD
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)

  @ht_dcphase: (data, lag) ->
    results = talib.HT_DCPHASE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)

  @ht_phasor: (data, lag) ->
    results = talib.HT_PHASOR
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    result =
      phase: _.last(results.outInPhase)
      quadrature: _.last(results.outQuadrature)
    result

  @ht_sine: (data, lag) ->
    results = talib.HT_SINE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)
    result =
      sine: _.last(results.outSine)
      leadsine: _.last(results.outLeadSine)
    result

   @ht_trendline: (data, lag) ->
    results = talib.HT_TRENDLINE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)

  @ht_trendmode: (data, lag) ->
    results = talib.HT_TRENDMODE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)

  # @imi: (open, close, lag, period) ->
  #   results = talib.IMI
  #     open: open
  #     close: close
  #     startIdx: 0
  #     endIdx: open.length - lag
  #     optInTimePeriod: period
  #   _.last(results)

  @kama: (data, lag, period) ->
    results = talib.KAMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @linearreg: (data, lag, period) ->
    results = talib.LINEARREG
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @linearreg_angle: (data, lag, period) ->
    results = talib.LINEARREG_ANGLE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @linearreg_intercept: (data, lag, period) ->
    results = talib.LINEARREG_INTERCEPT
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @linearreg_slope: (data, lag, period) ->
    results = talib.LINEARREG_SLOPE
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @ma: (data, lag, period, MAType) ->
    results = talib.MA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInMAType: MAType
    # array of floats
    results
    # _.last(results)

  @macd: (data, lag, FastPeriod, SlowPeriod, SignalPeriod) ->
    results = talib.MACD
     inReal: data
     startIdx: 0
     endIdx: data.length - lag
     optInFastPeriod: FastPeriod
     optInSlowPeriod: SlowPeriod
     optInSignalPeriod: SignalPeriod
    result =
      macd: _.last(results.outMACD)
      signal: _.last(results.outMACDSignal)
      histogram: _.last(results.outMACDHist)
    result

  @macdext: (data, lag, FastPeriod, FastMAType, SlowPeriod, SlowMAType, SignalPeriod, SignalMAType) ->
    results = talib.MACDEXT
     inReal: data
     startIdx: 0
     endIdx: data.length - lag
     optInFastPeriod: FastPeriod
     optInFastMAType: FastMAType
     optInSlowPeriod: SlowPeriod
     optInSlowMAType: SlowMAType
     optInSignalPeriod: SignalPeriod
     optInSignalMAType: SignalMAType
    result =
      macd: _.last(results.outMACD)
      signal: _.last(results.outMACDSignal)
      histogram: _.last(results.outMACDHist)
    result

  @macdfix: (data, lag, SignalPeriod) ->
    results = talib.MACDFIX
     inReal: data
     startIdx: 0
     endIdx: data.length - lag
     optInSignalPeriod: SignalPeriod
    result =
      macd: _.last(results.outMACD)
      signal: _.last(results.outMACDSignal)
      histogram: _.last(results.outMACDHist)
    result

  @mama: (data, lag, FastLimitPeriod, SlowLimitPeriod) ->
    results = talib.MAMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInFastLimit: FastLimitPeriod
      optInSlowLimit: SlowLimitPeriod
    result =
      mama: _.last(results.outMAMA)
      fama: _.last(results.outFAMA)
    result

  @mavp: (data, periods, lag, MinPeriod, MaxPeriod, MAType) ->
    results = talib.MAVP
      inReal: data
      inPeriods: periods
      startIdx: 0
      endIdx: data.length - lag
      optInMinPeriod: MinPeriod
      optInMaxPeriod: MaxPeriod
      optInMAType: MAType
    _.last(results)

  @max: (data, lag, period) ->
    results = talib.MAX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @maxindex: (data, lag, period) ->
    results = talib.MAXINDEX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @medprice: (high, low, lag, period) ->
    results = talib.MEDPRICE
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @mfi: (high, low, close, volume, lag, period) ->
    results = talib.MFI
      high: high
      low: low
      close: close
      volume: volume
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @midpoint: (data, lag, period) ->
    results = talib.MIDPOINT
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @midprice: (high, low, lag, period) ->
    results = talib.MIDPRICE
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @min: (data, lag, period) ->
    results = talib.MIN
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @minindex: (data, lag, period) ->
    results = talib.MININDEX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @minmax: (data, lag, period) ->
    results = talib.MINMAX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    result =
      min: _.last(results.outMin)
      max: _.last(results.outMax)
    result

   @minmaxindex: (data, lag, period) ->
    results = talib.MINMAXINDEX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    result =
      min: _.last(results.outMinIdx)
      max: _.last(results.outMaxIdx)
    result

  @minus_di: (high, low, close, lag, period) ->
    results = talib.MINUS_DI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @minus_dm: (high, low, lag, period) ->
    results = talib.MINUS_DM
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @mom: (data, lag, period) ->
    results = talib.MOM
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @natr: (high, low, close, lag, period) ->
    results = talib.NATR
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @obv: (data, volume, lag) ->
    results = talib.OBV
      inReal: data
      volume: volume
      startIdx: 0
      endIdx: data.length - lag
    _.last(results)

  @plus_di: (high, low, close, lag, period) ->
    results = talib.PLUS_DI
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @plus_dm: (high, low, lag, period) ->
    results = talib.PLUS_DM
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @ppo: (data, lag, FastPeriod, SlowPeriod, MAType) ->
    results = talib.PPO
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInFastPeriod: FastPeriod
      optInSlowPeriod: SlowPeriod
      optInMAType: MAType
    _.last(results)

  @roc: (data, lag, period) ->
    results = talib.ROC
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @rocp: (data, lag, period) ->
    results = talib.ROCP
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @rocr: (data, lag, period) ->
    results = talib.ROCR
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @rocr100: (data, lag, period) ->
    results = talib.ROCR100
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @rsi: (data, lag, period) ->
    results = talib.RSI
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @sar: (high, low, lag, accel, accelmax) ->
    results = talib.SAR
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInAcceleration: accel
      optInMaximum: accelmax
    _.last(results)

  @sarext: (high, low, lag, StartValue, OffsetOnReverse, AccelerationInitLong, AccelerationLong, AccelerationMaxLong, AccelerationInitShort, AccelerationShort, AccelerationMaxShort) ->
    results = talib.SAREXT
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - lag
      optInStartValue: StartValue
      optInOffsetOnReverse: OffsetOnReverse
      optInAccelerationInitLong: AccelerationInitLong
      optInAccelerationLong: AccelerationLong
      optInAccelerationMaxLong: AccelerationMaxLong
      optInAccelerationInitShort: AccelerationInitShort
      optInAccelerationShort: AccelerationShort
      optInAccelerationMaxShort: AccelerationMaxShort
    _.last(results)

  @sma: (data, lag, period) ->
    results = talib.SMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @stddev: (data, lag, period, NbDev) ->
    results = talib.STDDEV
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInNbDev: NbDev
    _.last(results)

  @stoch: (high, low, close, lag, fastK_period, slowK_period, slowK_MAType, slowD_period, slowD_MAType) ->
    results = talib.STOCH
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInFastK_Period: fastK_period
      optInSlowK_Period: slowK_period
      optInSlowK_MAType: slowK_MAType
      optInSlowD_Period: slowD_period
      optInSlowD_MAType: slowD_MAType
    result =
      K: _.last(results.outSlowK)
      D: _.last(results.outSlowD)
    result

  @stochf: (high, low, close, lag, fastK_period, fastD_period, fastD_MAType) ->
    results = talib.STOCHF
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInFastK_Period: fastK_period
      optInFastD_Period: fastD_period
      optInFastD_MAType: fastD_MAType
    result =
      K: _.last(results.outFastK)
      D: _.last(results.outFastD)
    result

  @stochrsi: (data, lag, period, fastK_period, fastD_period, fastD_MAType) ->
    results = talib.STOCHRSI
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInFastK_Period: fastK_period
      optInFastD_Period: fastD_period
      optInFastD_MAType: fastD_MAType
    result =
      K: _.last(results.outFastK)
      D: _.last(results.outFastD)
    result

  @sum: (data, lag, period) ->
    results = talib.SUM
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @t3: (data, lag, period, vfactor) ->
    results = talib.T3
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInVFactor: vfactor
    _.last(results)

  @tema: (data, lag, period) ->
    results = talib.TEMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @trange: (high, low, close, lag, period) ->
    results = talib.TRANGE
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @trima: (data, lag, period) ->
    results = talib.TRIMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @trix: (data, lag, period) ->
    results = talib.TRIX
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @tsf: (data, lag, period) ->
    results = talib.TSF
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)

  @typprice: (high, low, close, lag, period) ->
    results = talib.TYPPRICE
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @ultosc: (high, low, close, lag, Period1, Period2, Period3) ->
    results = talib.ULTOSC
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod1: Period1
      optInTimePeriod2: Period2
      optInTimePeriod3: Period3
    _.last(results)

  @variance: (data, lag, period, NbVar) ->
    results = talib.VAR
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInNbDev: NbVar
    _.last(results)

  @wclprice: (high, low, close, lag, period) ->
    results = talib.WCLPRICE
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @willr: (high, low, close, lag, period) ->
    results = talib.WILLR
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInTimePeriod: period
    _.last(results)

  @wma: (data, lag, period) ->
    results = talib.WMA
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
    _.last(results)
# /class TA

class MyTA
  # @accbands: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ad: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @adosc: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @adx: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @adxr: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @apo: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @aroon: (ins, results, helpers) ->
    diff = results.up - results.down
    #debug diff

    # plot
    #   AROON: diff

    if (diff > helpers.thresholdDiff)
      return ACTION_BUY
    else if (diff < helpers.thresholdDiff)
      return ACTION_SELL
    ACTION_NONE

  @aroonosc: (ins, results, helpers) ->
    if false
      return ACTION_BUY
    else if false
      return ACTION_SELL
    ACTION_NONE

  # @atr: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @avgprice: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @bbands: (ins, results, helpers) ->
    # plot
    #   BBANDS_UpperBand: results.UpperBand
    #   BBANDS_MiddleBand: results.MiddleBand
    #   BBANDS_LowerBand: results.LowerBand

    if (ins.price < results.LowerBand)
      return ACTION_BUY
    else if (ins.price > results.UpperBand)
      return ACTION_SELL
    ACTION_NONE

  # @beta: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @bop: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @cci: (ins, results, helpers) ->
    # plot
    #   CCI: results

    if results >= helpers.thresholdUpper
      return ACTION_BUY
    else if results <= helpers.thresholdLower
      return ACTION_SELL
    ACTION_NONE

  # @cmo: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @correl: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @dema: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @dx: (ins, results, helpers) ->
    # plot
    #   DX: results

    if results >= helpers.threshold
      resultsMinus = TA.minus_di(ins.high, ins.low, ins.close, context.lag, p.minus_di.args.period)
      resultsPlus = TA.plus_di(ins.high, ins.low, ins.close, context.lag, p.plus_di.args.period)
      if (resultsPlus > resultsMinus)
        return ACTION_BUY
      else if (resultsPlus < resultsMinus)
        return ACTION_SELL

  # @ema: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ht_dcperiod: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ht_dcphase: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ht_phasor: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ht_sine: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  #  @ht_trendline: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ht_trendmode: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @imi: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @kama: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @linearreg: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @linearreg_angle: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @linearreg_intercept: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @linearreg_slope: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @ma: (ins, results, helpers) ->
    short = TA.ma(ins.close, context.lag, helpers.periodShort, p.ma.args.MAType)
    shortOld = short[short.length - 2]
    shortNew = short[short.length - 1]

    long = TA.ma(ins.close, context.lag, helpers.periodLong, p.ma.args.MAType)
    longOld = long[long.length - 2]
    longNew = long[long.length - 1]

    # plot
    #   MA_short: shortNew
    #   MA_long: longNew

    if !shortOld or !longOld
      context.halt = true
      return

    diff = Fns.diff(shortNew, longNew)

    if (shortOld <= longOld) and (shortNew > longNew) and (diff > helpers.thresholdBuy)
      return ACTION_BUY
    else if (shortOld >= longOld) and (shortNew < longNew) and (diff < -helpers.thresholdSell)
      return ACTION_SELL
    ACTION_NONE

  @macd: (ins, results, helpers) ->
    # plot
    #   MACD_macd: results.macd + ins.price
    #   MACD_signal: results.signal + ins.price
    #   MACD_histogram: results.histogram + ins.price

    if (results.macd > results.signal)
      return ACTION_BUY
    else if (results.macd < results.signal)
      return ACTION_SELL
    ACTION_NONE

  # @macdext: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @macdfix: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @mama: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @mavp: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @max: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @maxindex: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @medprice: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @mfi: (ins, results, helpers) ->
    # plot
    #   MFI: results

    if (results < helpers.thresholdLower)
      return ACTION_BUY
    else if (results > helpers.thresholdUpper)
      return ACTION_SELL
    ACTION_NONE

  # @midpoint: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @midprice: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @min: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @minindex: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @minmax: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  #  @minmaxindex: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @minus_di: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @minus_dm: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @mom: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @natr: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @obv: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @plus_di: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @plus_dm: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ppo: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @roc: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @rocp: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @rocr: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @rocr100: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @rsi: (ins, results, helpers) ->
    if (results <= helpers.thresholdLower)
      return ACTION_BUY
    else if (results >= helpers.thresholdUpper)
      return ACTION_SELL
    ACTION_NONE

  # @sar: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @sarext: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @sma: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @stddev: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @stoch: (ins, results, helpers) ->
    # plot
    #   STOCH_K: results.K
    #   STOCH_D: results.D

    resultMax = Math.max(results.K, results.D)
    resultMin = Math.min(results.K, results.D)

    v = 1

    if (v == 1)
      context.last_STOCH_activatedLower ?= false
      context.last_STOCH_activatedUpper ?= false
      if (resultMin <= helpers.thresholdLower)
        context.last_STOCH_activatedLower = true
        context.last_STOCH_activatedUpper = false
      else if (resultMax >= helpers.thresholdUpper)
        context.last_STOCH_activatedUpper = true
        context.last_STOCH_activatedLower = false
      else
        if context.last_STOCH_activatedLower
          context.last_STOCH_activatedLower = false
          return ACTION_BUY
        else if context.last_STOCH_activatedUpper
          context.last_STOCH_activatedUpper = false
          return ACTION_SELL
    else if (v == 2)
      if (results.K > results.D)
        return ACTION_BUY
      else if (results.K < results.D)
        return ACTION_SELL
    ACTION_NONE

  # @stochf: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  @stochrsi: (ins, results, helpers) ->
    # plot
    #   STOCHRSI_K: results.K
    #   STOCHRSI_D: results.D

    result = results.D
    if !Fns.isSet(result)
      return

    openVal = _.last(ins.open)
    closeVal = _.last(ins.close)
    isLong = (closeVal > openVal)
    isShort = (closeVal < openVal)
    # if true
    #   isLong = !isLong
    #   isShort = !isShort

    if (result >= helpers.thresholdLower)
      return ACTION_BUY
      # if isLong
      #   return ACTION_BUY
      # else if isShort
      #   return ACTION_SELL
    else if (result <= helpers.thresholdUpper)
      return ACTION_SELL
      # if isLong
      #   return ACTION_SELL
      # else if isShort
      #   return ACTION_BUY
    ACTION_NONE

  # @sum: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @t3: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @tema: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @trange: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @trima: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @trix: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @tsf: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @typprice: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @ultosc: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @variance: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @wclprice: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @willr: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE

  # @wma: (ins, results, helpers) ->
  #   if false
  #     return ACTION_BUY
  #   else if false
  #     return ACTION_SELL
  #   ACTION_NONE
# /class MyTA

class Fns
  @isSet: (obj) ->
    return (typeof obj != "undefined")

  @diff: (x, y) ->
    100 * ((x - y) / ((x + y) / 2))

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

  @getParamDef: (arg) ->
    val = switch arg
      when "high" then null
      when "low" then null
      when "open" then null
      when "close" then null
      when "data" then null
      when "volume" then null
      when "lag" then null
      when "period" then Fns.getDef("period")
      when "MAType" then MATYPE_DEF
      else switch true
        when arg.includes("period") then Fns.getDef("period")
        when arg.includes("MAType") then MATYPE_DEF
        when arg.includes("NbDev") then NBDEV_DEF
        else UNSET_DEF
    return val

  @getDef: (arg) ->
    if !context.periodStr then context.periodStr = Fns.interval2period(GLOBAL.config.interval)
    if Fns.isSet(DEFS[context.periodStr])
      val = DEFS[context.periodStr][arg]
      if val
        return val
    return DEFS["DEF"][arg]

  # @getArgVals: (ins, fn, args) ->
  #   vals = []
  #   for idx, arg of args
  #     val = switch arg
  #       when "high" then ins.high
  #       when "low" then ins.low
  #       when "open" then ins.open
  #       when "close" then ins.close
  #       when "data" then ins.close
  #       when "volume" then ins.volumes
  #       when "lag" then context.lag
  #       when "period" then p[fn].args[arg]
  #       else p[fn].args[arg]
  #     vals.push(val)
  #   return vals

  @getArgValsObj: (ins, fn, args) ->
    vals = {}
    for idx, arg of args
      val = switch arg
        when "high" then ins.high
        when "low" then ins.low
        when "open" then ins.open
        when "close" then ins.close
        when "data" then ins.close
        when "volume" then ins.volumes
        when "lag" then context.lag
        when "period" then (if (context.periodG != UNSET_DEF) then context.periodG else p[fn].args[arg])
        else p[fn].args[arg]
      vals[arg] = val
    return vals

  @getFuncs: (theClass) ->
    ans = {}
    fns = (k for k, v of theClass when typeof v is 'function')
    for k, v of fns
      ans[v] = @getArgs(theClass, v)
      # debug " " + k + ": " + v + " /"
      # info TA[v].toString()
    return ans

  @getArgs: (theClass, fn) ->
    fstr = theClass[fn].toString()
    return fstr.match(/\(.*?\)/)[0].replace(/[()]/gi, '').replace(/\s/gi, '').split(',')

  @objToPermutations: (obj) ->
    perms = [{}]
    for arg, valOrg of obj
      permsClone = _.cloneDeep(perms)
      valArr = if Array.isArray(valOrg) then [valOrg] else valOrg.toString().split(',')
      for idx, val of valArr
        # debug "perms: #{fn}: #{arg}: #{idx}: #{val}"
        if idx == "0"
          for index in [0..perms.length - 1]
            perms[index][arg] = val
        else
          permsCopy = _.cloneDeep(permsClone)
          for index in [0..permsCopy.length - 1]
            permsCopy[index][arg] = val
          perms = perms.concat(permsCopy)
    perms
# /class Fns

# PARAMS
context.lag = params.add "Lag", Fns.getDef("lag")
context.periodG = params.add "Period (Global Override)", UNSET_DEF
context.tradePM = params.add "Trade Plus/Minus", TRADE_PM_DEF

# params meta
pmHelpers = {
  aroon: {
    thresholdDiff: "33",
  },
  cci: {
    thresholdUpper: "100",
    thresholdLower: "-100",
  },
  dx: {
    threshold: "10",
  },
  ma: {
    periodShort: "10",
    periodLong: "21",
    thresholdBuy: ".02",
    thresholdSell: ".005",
  },
  macd: {
  },
  mfi: {
    thresholdUpper: "80",
    thresholdLower: "20",
  },
  rsi: {
    thresholdUpper: "70",
    thresholdLower: "30",
  },
  stoch: {
    thresholdUpper: "80",
    thresholdLower: "20",
  },
  stochrsi: {
    thresholdUpper: "80",
    thresholdLower: "20",
  },
}
pmArgs = {
  macd: {
    FastPeriod: "12",
    SlowPeriod: "26",
    SignalPeriod: "9",
  },
}

p = {} # params answers

funcsAll = Fns.getFuncs(TA)
for fn, args of funcsAll
  p[fn] = {
    helpers: {},
    args: {},
  }
  params.add "▼ TAlib: #{fn}", false
  for arg, val of pmHelpers[fn]
    p[fn].helpers[arg] = params.add "#{fn}: #{arg}", "#{val}"
  for arg, val of pmArgs[fn]
    p[fn].args[arg] = params.add "#{fn}: #{arg}", "#{val}"
  for idx, arg of args
    def = Fns.getParamDef(arg)
    if (def != null)
      p[fn].args[arg] = params.add "#{fn}: #{arg}", "#{def}"
      # debug " " + idx + ": " + arg + " /"

funcs = {}

init: (context) ->
  # for fn, args of funcsAll
  #   debug " " + fn + ": " + args + " /"
  #   # info TA[v].toString()
  #   for idx, arg of args
  #     debug " " + idx + ": " + arg + " /"

  # filter to only funcs w/ all args set
  for fn, args of funcsAll
    if !Fns.isSet(MyTA[fn])
      continue
    pass = true
    for arg, val of p[fn].args
      # debug "args: #{fn}: #{arg}: #{val}"
      if (val == UNSET_DEF) or !Fns.isSet(val)
        pass = false
    for arg, val of p[fn].helpers
      # debug "helpers: #{fn}: #{arg}: #{val}"
      if (val == UNSET_DEF) or !Fns.isSet(val)
        pass = false
    if pass
      # debug "PASS: #{fn}"
      funcs[fn] = args
    else
      # debug "FAIL: #{fn}"

handle: (context, data) ->
  ins = data.instruments[0]
  balA = @portfolios[ins.market].positions[ins.asset()].amount
  balC = @portfolios[ins.market].positions[ins.curr()].amount
  storage.priceInit ?= _.last(ins.open)
  storage.balInit ?= (balA * storage.priceInit) + balC
  storage.startedAt ?= data.at

  i = 0
  actBuys = actSells = actNones = 0
  for fn, args of funcs
    i++
    valsObjTA = Fns.getArgValsObj(ins, fn, args)
    # for q, z of valsObjTA
    #   debug "valsObjTA: fn: #{fn}; q: #{q}; z: #{z};"
    # stop()
    argsPerm = Fns.objToPermutations(valsObjTA)
    for argsPermIdx, argsPermObj of argsPerm
      argsVals = _.values(argsPermObj)
      # for q, z of argsPermObj
      #   debug "argsPermObj: fn: #{fn}; q: #{q}; z: #{z};"
      # for q, z of argsVals
      #   debug "argsVals: fn: #{fn}; q: #{q}; z: #{z};"
      # stop()
      res = TA[fn].apply(this, argsVals)

      helpers = Fns.objToPermutations(p[fn].helpers)
      for helpersIdx, helpersObj of helpers
        act = MyTA[fn](ins, res, helpersObj)
        # debug "act: #{fn}: #{act}"

        if !act or (act == ACTION_NONE)
          actNones++
        else if (act == ACTION_BUY)
          actBuys++
        else if (act == ACTION_SELL)
          actSells++

  debug "buys: #{actBuys}; sells: #{actSells}; nones: #{actNones}"
  # debug "balA: #{balA}; balC: #{balC}"

  if DO_NONES and (actNones > actBuys) and (actNones > actSells)
    # do nothing
  else if (actBuys > actSells) and (balC >= MIN_AMOUNT_CURR)
    tradePrice = ins.price + context.tradePM
    success = trading.buy ins, 'limit', balC / tradePrice, tradePrice
  else if (actSells > actBuys) and (balA >= MIN_AMOUNT_ASSET)
    tradePrice = ins.price - context.tradePM
    success = trading.sell ins, 'limit', balA, tradePrice

onRestart: ->
  debug "Bot restarted at #{new Date(data.at)}"

onStop: ->
  ins = data.instruments[0]
  balA = @portfolios[ins.market].positions[ins.asset()].amount
  balC = @portfolios[ins.market].positions[ins.curr()].amount

  warn "======= STOPPING ======="
  warn "Bot started at #{new Date(storage.startedAt)}"
  warn "Bot stopped at #{new Date(data.at)}"
  debug "Final price: #{(ins.price)} (Initial: #{(storage.priceInit)})"
  balFinal = (balA * ins.price) + balC
  debug "Final balance: #{(balFinal)} (Initial: #{(storage.balInit)})"
  balPctDelta = balFinal / storage.balInit
  mktPctDelta = ins.price / storage.priceInit
  debug "Balance % Delta: #{(balPctDelta)} (Market: #{(mktPctDelta)})"

  debug "/"
  debug "/"
  debug "/"


    ##### define indicator TA #######
    # accbands = TA.accbands(ins.high, ins.low, ins.close, context.lag, context.period)
    # ad = TA.ad(ins.high, ins.low, ins.close, ins.volumes, context.lag, context.period)
    # adosc = TA.adosc(ins.high, ins.low, ins.close, ins.volumes, context.lag, context.FastPeriod, context.SlowPeriod)
    # adx = TA.adx(ins.high, ins.low, ins.close, context.lag, context.period)
    # adxr = TA.adxr(ins.high, ins.low, ins.close, context.lag, context.period)
    # apo = TA.apo(ins.close, context.lag, context.FastPeriod, context.SlowPeriod, context.MAType)
    # aroon = TA.aroon(ins.high, ins.low, context.lag, context.period)
    # aroonosc = TA.aroonosc(ins.high, ins.low, context.lag, context.period)
    # atr = TA.atr(ins.high, ins.low, ins.close, context.lag, context.period)
    # avgprice = TA.avgprice(ins.open, ins.high, ins.low, ins.close, context.lag, context.period)
    # bbands = TA.bbands(ins.close, context.period, context.lag, context.NbDevUp, context.NbDevDn, context.MAType)
    # beta = TA.beta(ins.high, ins.low, context.lag, context.period)
    # bop = TA.bop(ins.open, ins.high, ins.low, ins.close, context.lag)
    # cci = TA.cci(ins.high, ins.low, ins.close, context.lag, context.period)
    # cmo = TA.cmo(ins.close, context.lag, context.period)
    # correl = TA.correl(ins.high, ins.low, context.lag, context.period)
    # dema = TA.dema(ins.close, context.lag, context.period)
    # dx = TA.dx(ins.high, ins.low, ins.close, context.lag, context.period)
    # ema = TA.ema(ins.close, context.lag, context.period)
    # ht_dcperiod = TA.ht_dcperiod(ins.close, context.lag)
    # ht_dcphase = TA.ht_dcphase(ins.close, context.lag)
    # ht_phasor = TA.ht_phasor(ins.close, context.lag)
    # ht_sine = TA.ht_sine(ins.close, context.lag)
    # ht_trendline = TA.ht_trendline(ins.close, context.lag)
    # ht_trendmode = TA.ht_trendmode(ins.close, context.lag)
    # imi = TA.imi(ins.open, ins.close, context.lag, context.period)
    # kama = TA.kama(ins.close, context.lag, context.period)
    # linearreg = TA.linearreg(ins.close, context.lag, context.period)
    # linearreg_angle = TA.linearreg_angle(ins.close, context.lag, context.period)
    # linearreg_intercept = TA.linearreg_intercept(ins.close, context.lag, context.period)
    # linearreg_slope = TA.linearreg_slope(ins.close, context.lag, context.period)
    # ma = TA.ma(ins.close, context.lag, context.period, context.MAType)
    # macd = TA.macd(ins.close, context.lag, context.FastPeriod, context.SlowPeriod, context.SignalPeriod)
    # macdext = TA.macdext(ins.close, context.lag, context.FastPeriod, context.FastMAType, context.SlowPeriod, context.SlowMAType, context.SignalPeriod, context.SignalMAType)
    # macdfix = TA.macdfix(ins.close, context.lag, context.SignalPeriod)
    # mama = TA.mama(ins.close, context.lag, context.FastLimitPeriod, context.SlowLimitPeriod)
    # mavp = TA.mavp(ins.close, context.periods, context.lag, context.MinPeriod, context.MaxPeriod, context.MAType)
    # max_high = TA.max(ins.high, context.lag, context.period)
    # max_high = TA.max(ins.high, context.lag, context.period)
    # maxindex = TA.maxindex(ins.close, context.lag, context.period)
    # medprice = TA.medprice(ins.high, ins.low, context.lag, context.period)
    # mfi = TA.mfi(ins.high, ins.low, ins.close, ins.volumes, context.lag, context.period)
    # midpoint = TA.midpoint(ins.close, context.lag, context.period)
    # midprice = TA.midprice(ins.high, ins.low, context.lag, context.period)
    # min_low = TA.min(ins.low, context.lag, context.period)
    # minindex = TA.minindex(ins.close, context.lag, context.period)
    # minmax = TA.minmax(ins.close, context.lag, context.period)
    # minmaxindex = TA.minmaxindex(ins.close, context.lag, context.period)
    # minus_di = TA.minus_di(ins.high, ins.low, ins.close, context.lag, context.period)
    # minus_dm = TA.minus_dm(ins.high, ins.low, context.lag, context.period)
    # mom = TA.mom(ins.close, context.lag, context.period)
    # natr = TA.natr(ins.high, ins.low, ins.close, context.lag, context.period)
    # obv = TA.obv(ins.close, ins.volumes, context.lag)
    # plus_di = TA. plus_di(ins.high, ins.low, ins.close, context.lag, context.period)
    # plus_dm = TA.plus_dm(ins.high, ins.low, context.lag, context.period)
    # ppo = TA.ppo(ins.close, context.lag, context.FastPeriod, context.SlowPeriod, context.MAType)
    # roc = TA.roc(ins.close, context.lag, context.period)
    # rocp = TA.rocp(ins.close, context.lag, context.period)
    # rocr = TA.rocr(ins.close, context.lag, context.period)
    # rocr100 = TA.rocr100(ins.close, context.lag, context.period)
    # rsi = TA.rsi(ins.close, context.lag, context.period)
    # sar = TA.sar(ins.high, ins.low, context.lag, context.accel, context.accelmax)
    # sarext = TA.sarext(ins.high, ins.low, context.lag, context.StartValue, context.OffsetOnReverse, context.AccelerationInitLong, context.AccelerationLong, context.AccelerationMaxLong, context.AccelerationInitShort, context.AccelerationShort, context.AccelerationMaxShort)
    # sma = TA.sma(ins.close, context.lag, context.period)
    # stddev = TA.stddev(ins.close, context.lag, context.period, context.NbDev)
    # stoch = TA.stoch(ins.high, ins.low, ins.close, context.lag, context.fastK_period, context.slowK_period, context.slowK_MAType, context.slowD_period, context.slowD_MAType)
    # stochf = TA.stochf(ins.high, ins.low, ins.close, context.lag, context.fastK_period, context.fastD_period, context.fastD_MAType)
    # stochrsi = TA.stochrsi(ins.close, context.lag, context.period, context.fastK_period, context.fastD_period, context.fastD_MAType)
    # sum = TA.sum(ins.close, context.lag, context.period)
    # t3 = TA.t3(ins.close, context.lag, context.period, context.vfactor)
    # tema = TA.tema(ins.close, context.lag, context.period)
    # trange = TA.trange(ins.high, ins.low, ins.close, context.lag, context.period)
    # trima = TA.trima(ins.close, context.lag, context.period)
    # trix = TA.trix(ins.close, context.lag, context.period)
    # tsf = TA.tsf(ins.close, context.lag, context.period)
    # typprice = TA.typprice(ins.high, ins.low, ins.close, context.lag, context.period)
    # ultosc = TA.ultosc(ins.high, ins.low, ins.close, context.lag, context.Period1, context.Period2, context.Period3)
    # variance = TA.variance(ins.close, context.lag, context.period, context.NbVar)
    # wclprice = TA.wclprice(ins.high, ins.low, ins.close, context.lag, context.period)
    # willr = TA.willr(ins.high, ins.low, ins.close, context.lag, context.period)
    # wma = TA.wma(ins.close, context.lag, context.period)

    ######    debug indicators ################
    # debug "#{accbands.UpperBand}  #{accbands.MiddleBand} #{accbands.LowerBand}"
    # debug "#{ad}"
    # debug "#{adosc}"
    # debug "#{adx}"
    # debug "#{adxr}"
    # debug "#{apo}"
    # debug "#{aroon.up} #{aroon.down}"
    # debug "#{aroonosc}"
    # debug "#{atr} "
    # debug "#{avgprice}"
    # debug "#{bbands.UpperBand} #{bbands.MiddleBand} #{bbands.LowerBand}"
    # debug "#{beta}"
    # debug "#{bop}"
    # debug "#{cci}"
    # debug "#{cmo}"
    # debug "#{correl}"
    # debug "#{dema}"
    # debug "#{dx}"
    # debug "#{ema}"
    # debug "#{ht_dcperiod}"
    # debug "#{ht_dcphase}"
    # debug "#{ht_phasor.phase} #{ht_phasor.quadrature}"
    # debug "#{ht_sine.sine} #{ht_sine.leadsine}"
    # debug "#{ht_trendline}"
    # debug "#{ht_trendmode}"
    # debug "#{imi}"
    # debug "#{kama}"
    # debug "#{linearreg}"
    # debug "#{linearreg_angle}"
    # debug "#{linearreg_intercept}"
    # debug "#{linearreg_slope}"
    # debug "#{ma}"
    # debug "#{macd.macd}  #{macd.signal}  #{macd.histogram}"
    # debug "#{macdext.macd}  #{macdext.signal} #{macdext.histogram}"
    # debug "#{macdfix.macd}  #{macdfix.signal} #{macdfix.histogram}"
    # debug "#{mama.mama} #{mama.fama}"
    # debug "#{mavp}"
    # debug "#{max_high}
    # debug "#{maxindex}"
    # debug "#{medprice}"
    # debug "#{mfi}"
    # debug "#{midpoint}"
    # debug "#{midprice}"
    # debug "#{min_low}"
    # debug "#{minindex}"
    # debug "#{minmax.min} #{minmax.max}"
    # debug "#{minmaxindex.min} #{minmaxindex.max}"
    # debug "#{minus_di}"
    # debug "#{minus_dm}"
    # debug "#{mom}"
    # debug "#{natr}"
    # debug "#{obv}"
    # debug "#{plus_di}"
    # debug "#{plus_dm}"
    # debug "#{ppo}"
    # debug "#{roc}"
    # debug "#{rocp}"
    # debug "#{rocr}"
    # debug "#{rocr100}"
    # debug "#{rsi}"
    # debug "#{sar}"
    # debug "#{sarext}"
    # debug "#{sma}"
    # debug "#{stddev}"
    # debug "#{stoch.K} #{stoch.D}"
    # debug "#{stochf.K} #{stochf.D}"
    # debug "#{stochrsi.K}#{stochrsi.D} "
    # debug "#{sum}"
    # debug "#{t3}"
    # debug "#{tema}"
    # debug "#{trange}"
    # debug "#{trima}"
    # debug "#{trix}"
    # debug "#{tsf}"
    # debug "#{typprice}"
    # debug "#{ultosc} "
    # debug "#{variance}"
    # debug "#{wclprice}"
    # debug "#{willr}"
    # debug "#{wma}"
