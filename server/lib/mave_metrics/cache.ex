defmodule MaveMetrics.PartitionedCache do
  use Nebulex.Cache,
    otp_app: :mave_metrics,
    adapter: Nebulex.Adapters.Partitioned,
    primary_storage_adapter: Nebulex.Adapters.Local,
    default_key_generator: __MODULE__

  @behaviour Nebulex.Caching.KeyGenerator

  @impl true
  def generate(mod, fun, args), do: :erlang.phash2({mod, fun, args})
end
