"""
BaselineRsiEmaStrategy — Phase 1.3

Changes from 1.2:
  - Exit signals split into separate tags (rsi_overbought / ema_cross) so
    backtest results show which exit is profitable vs harmful.
  - Key thresholds converted to Hyperopt parameters so Freqtrade can search
    for the best values automatically.
  - EMA cross exit can be disabled entirely by Hyperopt if it's net-negative.

Hyperopt spaces: buy, sell, roi, stoploss.
In-sample period:    20250524–20260101  (use for --hyperopt run)
Out-of-sample:       20260101–          (use for final backtest validation)

Not financial advice. Do not use with real funds without independent review.
"""

import talib.abstract as ta
from pandas import DataFrame

from freqtrade.strategy import BooleanParameter, IntParameter, IStrategy


class BaselineRsiEmaStrategy(IStrategy):
    INTERFACE_VERSION = 3

    can_short = False
    timeframe = "1h"
    startup_candle_count = 200

    # ------------------------------------------------------------------ #
    # Exit targets — searched by Hyperopt (roi + stoploss spaces)         #
    # ------------------------------------------------------------------ #
    minimal_roi = {
        "0": 0.06,
        "120": 0.04,
        "360": 0.02,
        "720": 0.01,
    }

    stoploss = -0.05
    trailing_stop = False
    process_only_new_candles = True

    # ------------------------------------------------------------------ #
    # Hyperopt parameters                                                  #
    # ------------------------------------------------------------------ #
    # Entry
    buy_rsi_entry = IntParameter(20, 55, default=40, space="buy", optimize=True)

    # Exit
    sell_rsi_exit = IntParameter(60, 90, default=70, space="sell", optimize=True)
    # Lets Hyperopt disable the EMA cross exit entirely if it's net-negative
    sell_ema_cross_enabled = BooleanParameter(default=True, space="sell", optimize=True)

    # ------------------------------------------------------------------ #
    # Fixed indicator periods (not hyperopt — recomputing EMAs per trial  #
    # is expensive; thresholds are what matter)                           #
    # ------------------------------------------------------------------ #
    ema_long_period: int = 200
    ema_medium_period: int = 50
    ema_short_period: int = 20
    rsi_period: int = 14

    # ------------------------------------------------------------------ #
    # Indicators                                                           #
    # ------------------------------------------------------------------ #
    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe["ema200"] = ta.EMA(dataframe, timeperiod=self.ema_long_period)
        dataframe["ema50"] = ta.EMA(dataframe, timeperiod=self.ema_medium_period)
        dataframe["ema20"] = ta.EMA(dataframe, timeperiod=self.ema_short_period)
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=self.rsi_period)
        return dataframe

    # ------------------------------------------------------------------ #
    # Entry                                                                #
    # ------------------------------------------------------------------ #
    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                (dataframe["close"] > dataframe["ema50"])
                & (dataframe["rsi"] > self.buy_rsi_entry.value)
                & (dataframe["rsi"].shift(1) <= self.buy_rsi_entry.value)
                & (dataframe["volume"] > 0)
            ),
            ["enter_long", "enter_tag"],
        ] = [1, "rsi_ema_cross"]

        return dataframe

    # ------------------------------------------------------------------ #
    # Exit                                                                 #
    # ------------------------------------------------------------------ #
    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Exit 1: RSI overbought — take profit before reversal.
        dataframe.loc[
            (
                (dataframe["rsi"] > self.sell_rsi_exit.value)
                & (dataframe["volume"] > 0)
            ),
            ["exit_long", "exit_tag"],
        ] = [1, "rsi_overbought"]

        # Exit 2: EMA20 crosses below EMA50 — medium-term trend has turned.
        # Hyperopt can disable this entirely via sell_ema_cross_enabled.
        if self.sell_ema_cross_enabled.value:
            dataframe.loc[
                (
                    (dataframe["ema20"] < dataframe["ema50"])
                    & (dataframe["ema20"].shift(1) >= dataframe["ema50"].shift(1))
                    & (dataframe["volume"] > 0)
                ),
                ["exit_long", "exit_tag"],
            ] = [1, "ema_cross"]

        return dataframe
