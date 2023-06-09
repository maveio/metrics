defmodule MaveMetrics.Keys do
  @moduledoc """
  The Keys context.
  """

  import Ecto.Query, warn: false
  import EctoCase
  alias MaveMetrics.Repo

  use Nebulex.Caching
  alias MaveMetrics.PartitionedCache, as: Cache

  @ttl :timer.seconds(30)

  alias MaveMetrics.Key

  @decorate cacheable(cache: Cache, key: {Key, key}, opts: [ttl: @ttl])
  def get_key(key) do
    Key |> where([k], k.key == ^key) |> where([k], is_nil(k.disabled_at)) |> Repo.one()
  end

  def get_keys() do
    Key
    |> Repo.all()
    |> Enum.map(fn key ->
      %{key: key.key, disabled_at: key.disabled_at}
    end)
  end

  def revoke_key(%{"key" => key}) do
    with %Key{} = key <- Key |> where([k], k.key == ^key) |> Repo.one(),
     {:ok, _} <- key |> Key.changeset(%{disabled_at: DateTime.utc_now()}) |> Repo.update() do
      :ok
    else
      _ -> :error
    end
  end

  def revoke_key(_params), do: :error

  def valid_key?(key) do
    case get_key(key) do
      nil -> {:error, "Invalid key"}
      key -> {:ok, key}
    end
  end

  def create_key(%{"key" => key}) when not is_nil(key) do
    Key.changeset(%Key{}, %{key: key})
    |> Repo.insert()
    |> case do
      {:ok, result} ->
        {:ok, result.key}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_key(_params) do
    key = generate_key()
    create_key(%{"key" => key})
  end

  defp generate_key() do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end
end
