defmodule Restruct do
  @moduledoc """
  Restruct is a library for migrating struct values to conform to their current
  definitions.

  This is useful when you have a struct value that was created with an older
  version of the defining module and you want to update it to match the current
  definition.
  """

  @doc """
  Ensure a struct value conforms to its current definition. Any keys that have
  been removed from the definition will be removed, and any new keys will be
  added and initialized to their defined defaults.

  **Warning:** There is a potential for data loss when using this function.
  In addition to dropping values for any keys that have been removed from the
  definition, plain maps that use structs for keys may end up with fewer entries
  if any of those keys become equal after having fields removed (the `:keep`
  option can be used to prevent this).

  ## Options

  * `:recursive` - If `true`, the function will recursively migrate structs in
    nested data structures. Setting this option to false and passing a value
    other than a struct is a no-op. Defaults to `true`.
  * `:keep` - If `true`, the function will keep extra fields that are not
    defined in the struct. Defaults to `false`.

  ## Examples

      iex> defmodule X do
      iex>   defstruct foo: nil, bar: 8
      iex> end
      iex> value = %{__struct__: X, foo: 1, baz: 2}
      iex> Restruct.migrate(value)
      %{__struct__: X, foo: 1, bar: 8}
      iex> Restruct.migrate(value, keep: true)
      %{__struct__: X, foo: 1, bar: 8, baz: 2}
      iex> :code.purge(X)
      iex> :code.delete(X)

  """
  def migrate(value, opts \\ []) do
    opts = Keyword.put_new(opts, :recursive, true)

    cond do
      is_struct(value) and not is_struct(value, MapSet) ->
        do_migrate(value, opts)

      opts[:recursive] == true ->
        do_migrate(value, opts)

      true ->
        value
    end
  end

  defp do_migrate(%MapSet{} = value, opts) do
    value
    |> MapSet.to_list()
    |> do_migrate(opts)
    |> MapSet.new()
  end

  defp do_migrate(%struct{} = value, opts) do
    opts = Keyword.put_new(opts, :recursive, true)

    filtered_map =
      if opts[:keep] do
        value |> Map.from_struct()
      else
        valid_keys = struct(struct) |> Map.from_struct() |> Map.keys()
        value |> Map.from_struct() |> Map.take(valid_keys)
      end

    filtered_map =
      if opts[:recursive] == true do
        Map.new(filtered_map, fn {k, v} ->
          {do_migrate(k, opts), do_migrate(v, opts)}
        end)
      else
        filtered_map
      end

    if opts[:keep] == true do
      Map.merge(struct(struct), filtered_map)
    else
      struct(struct, filtered_map)
    end
  end

  defp do_migrate(value, opts) when is_map(value) do
    Map.new(value, fn {k, v} ->
      {do_migrate(k, opts), do_migrate(v, opts)}
    end)
  end

  defp do_migrate(value, opts) when is_list(value) do
    Enum.map(value, &do_migrate(&1, opts))
  end

  defp do_migrate(value, opts) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> do_migrate(opts)
    |> List.to_tuple()
  end

  defp do_migrate(value, _opts), do: value
end
