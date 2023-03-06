defmodule EctoCase do
  defmacro case_when(condition, then, otherwise) do
    quote do
      fragment(
        """
        CASE WHEN ? THEN ?
             ELSE ?
        END
        """,
        unquote(condition),
        unquote(then),
        unquote(otherwise)
      )
    end
  end
end
