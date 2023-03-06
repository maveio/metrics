defmodule MaveMetrics.Video.Metadata do
  use Ecto.Schema
  # import Ecto.Changeset

  @primary_key false

  embedded_schema do
    timestamps()
  end
end
