defmodule MaveMetrics.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @foreign_key_type :binary_id
    end
  end
end
