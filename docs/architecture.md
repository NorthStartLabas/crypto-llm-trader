# Architecture

## Overview

`crypto-llm-trader` is a thin wrapper around Freqtrade. All trading logic lives inside Freqtrade;
this project contributes configuration, operational scripts, and (in later phases) custom strategies
and ML models mounted into the container at runtime.

```
┌─────────────────────────────────────────────────────────────┐
│  Host machine                                               │
│                                                             │
│  .env ──────────────────────────────────────────────────┐  │
│  user_data/ (mounted volume) ───────────────────────┐   │  │
│                                                     │   │  │
│  ┌──────────────────────────────────────────────────┼───┼─┐│
│  │  Docker Compose                                  │   │  ││
│  │                                                  │   │  ││
│  │  ┌─────────────────────────────────────────────┐ │   │  ││
│  │  │  freqtrade (freqtradeorg/freqtrade:stable)  │◄┘   │  ││
│  │  │                                             │◄────┘  ││
│  │  │  - strategy engine                          │        ││
│  │  │  - order management (dry-run)               │        ││
│  │  │  - REST API  ──► 127.0.0.1:8080             │        ││
│  │  │  - SQLite trade DB                          │        ││
│  │  └─────────────────────────────────────────────┘        ││
│  └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
         │
         │ CCXT (HTTP)
         ▼
    Kraken API (public endpoints only in dry-run)
```

## Key design decisions

### No upstream modifications
Freqtrade is consumed as a pre-built Docker image. We never fork or patch it. Custom strategies
are dropped into `user_data/strategies/` and picked up at runtime via the strategy path.

### Mounted volume
`./user_data` on the host is mounted to `/freqtrade/user_data` inside the container. This means:
- Configs, strategies, and logs are version-controllable (with appropriate gitignore rules).
- The container is ephemeral; all persistent state is on the host.

### API server
The Freqtrade REST API is enabled and bound to `127.0.0.1:8080`. FreqUI (the official React
dashboard) connects to this endpoint. The port is never published to `0.0.0.0`.

### Dry-run enforcement
`dry_run: true` is set in the JSON config. `run_dry.sh` additionally checks the `.env` file and
refuses to start if `DRY_RUN` is not `true`. Belt-and-suspenders.

## Future layers (not implemented yet)

```
Phase 2 — FreqAI
  user_data/freqaimodels/   ← trained model artifacts
  custom strategy that calls FreqAI prediction endpoint

Phase 3 — LLM signal layer
  Optional sidecar service
  Writes signals to a shared file or lightweight queue
  FreqAI/strategy reads signals as features — no direct order execution by LLM
```

The LLM layer will never place orders directly. It produces features that a deterministic
Freqtrade strategy uses to make entry/exit decisions.
