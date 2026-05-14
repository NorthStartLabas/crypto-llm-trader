"""
Phase 0 placeholder strategy — no trading logic.
This strategy never enters or exits any trades.
It exists solely so the Freqtrade container starts cleanly in dry-run mode
while Phase 0/0.5 validation is in progress.

Replace this file in Phase 1 with a real strategy.
"""
from pandas import DataFrame

from freqtrade.strategy import IStrategy


class DryRunPlaceholder(IStrategy):
    INTERFACE_VERSION = 3

    # ROI set high enough that it is never reached — no exits via ROI
    minimal_roi = {"0": 100}

    # Stop-loss set near -100% — no exits via stoploss either
    stoploss = -0.99

    timeframe = "1h"
    process_only_new_candles = True
    startup_candle_count = 0

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Never enter a trade
        dataframe["enter_long"] = 0
        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Never exit a trade
        dataframe["exit_long"] = 0
        return dataframe
