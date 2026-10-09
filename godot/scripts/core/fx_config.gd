class_name FxConfig
## Perf caps for visual effects (visual only; never gameplay). Split out of Config
## so config.gd stays focused on gameplay tuning. Readers: world/effects.gd.

const FX_MAX_ITEMS := 400  # live fx items; lobs are gameplay-relevant and are never culled
const FX_MAX_DEBRIS := 48  # live debris chunks from structure deaths
