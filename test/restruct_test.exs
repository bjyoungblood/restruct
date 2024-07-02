defmodule RestructTest do
  use ExUnit.Case
  doctest Restruct

  test "adds missing fields, removes extra fields" do
    defmodule X do
      defstruct [:foo, :bar, :baz]
    end

    old_x = struct(X, foo: 1, bar: 2, baz: 3)

    Code.put_compiler_option(:ignore_module_conflict, true)

    defmodule X do
      defstruct foo: nil, baz: nil, qux: 10
    end

    Code.put_compiler_option(:ignore_module_conflict, false)

    assert is_map_key(old_x, :bar)
    assert is_map_key(old_x, :baz)
    refute is_map_key(old_x, :qux)

    new_x = Restruct.migrate(old_x)

    assert is_struct(new_x, X)
    assert %{__struct__: X, foo: 1, baz: 3, qux: 10} == new_x
    refute is_map_key(new_x, :bar)

    {:ok, new_x} = Restruct.migrate({:ok, old_x})
    assert %{__struct__: X, foo: 1, baz: 3, qux: 10} == new_x

    {:ok, new_x} = Restruct.migrate({:ok, old_x}, recursive: false)
    assert old_x == new_x

    [foo: new_x] = Restruct.migrate(foo: old_x)
    assert %{__struct__: X, foo: 1, baz: 3, qux: 10} == new_x

    [foo: new_x] = Restruct.migrate([foo: old_x], recursive: false)
    assert old_x == new_x

    old_mapset = MapSet.new([old_x])
    assert new_mapset = %MapSet{} = Restruct.migrate(old_mapset)
    refute MapSet.equal?(old_mapset, new_mapset)

    old_mapset = MapSet.new([old_x])
    assert new_mapset = %MapSet{} = Restruct.migrate(old_mapset, recursive: false)
    assert MapSet.equal?(old_mapset, new_mapset)

    new_x = Restruct.migrate(old_x, keep: true)
    assert is_struct(new_x, X)
    assert %{__struct__: X, foo: 1, bar: 2, baz: 3, qux: 10} == new_x

    refute is_map_key(struct(X), :bar)

    :code.purge(X)
    :code.delete(X)
  end

  test "recursion" do
    defmodule Y do
      defstruct [:foo, :bar, :baz]
    end

    defmodule Z do
      defstruct [:qux, :quux]
    end

    old_y =
      struct(Y,
        foo: %{
          struct(Z, qux: 1, quux: 2) => struct(Z, qux: 3, quux: 4),
          struct(Z, qux: 1, quux: nil) => 8,
          :bar => struct(Z, qux: 5, quux: 6)
        },
        bar: [
          6,
          7,
          "8",
          struct(Z, qux: 9, quux: 10),
          struct(Z, qux: %{foo: struct(Z, qux: 11, quux: struct(Z, qux: 12))})
        ],
        baz: 999
      )

    Code.put_compiler_option(:ignore_module_conflict, true)

    defmodule Y do
      defstruct foo: nil, bar: nil, biz: 123
    end

    defmodule Z do
      defstruct [:qux, :qiz]
    end

    Code.put_compiler_option(:ignore_module_conflict, false)

    assert is_struct(old_y, Y)
    assert is_map_key(old_y, :baz)
    refute is_map_key(old_y, :biz)
    assert is_map_key(old_y.foo, %{__struct__: Z, qux: 1, quux: nil})
    assert is_map_key(old_y.foo, %{__struct__: Z, qux: 1, quux: 2})

    assert %{__struct__: Z, qux: 3, quux: 4} =
             Map.get(old_y.foo, %{__struct__: Z, qux: 1, quux: 2})

    assert [
             6,
             7,
             "8",
             %{__struct__: Z, qux: 9, quux: 10},
             %{
               __struct__: Z,
               qux: %{foo: %{__struct__: Z, qux: 11, quux: %{__struct__: Z, qux: 12, quux: nil}}},
               quux: nil
             }
           ] == old_y.bar

    assert old_y.baz == 999
    assert length(Map.values(old_y.foo)) == 3

    new_y = Restruct.migrate(old_y)

    assert is_struct(new_y, Y)
    refute is_map_key(new_y, :baz)
    assert is_map_key(new_y, :biz)
    assert is_map_key(new_y.foo, %{__struct__: Z, qux: 1, qiz: nil})

    refute %{__struct__: Z, qux: 3, quux: 4} ==
             Map.get(new_y.foo, %{__struct__: Z, qux: 1, qiz: nil})

    assert [
             6,
             7,
             "8",
             %{__struct__: Z, qux: 9, qiz: nil},
             %{__struct__: Z, qux: %{foo: %{__struct__: Z, qux: 11, qiz: nil}}, qiz: nil}
           ] == new_y.bar

    assert new_y.biz == 123
    assert length(Map.values(new_y.foo)) == 2

    new_y = Restruct.migrate(old_y, recursive: false)

    assert %{
             __struct__: Y,
             foo: %{
               %{__struct__: Z, qux: 1, quux: 2} => %{__struct__: Z, qux: 3, quux: 4},
               %{__struct__: Z, qux: 1, quux: nil} => 8,
               :bar => %{__struct__: Z, qux: 5, quux: 6}
             },
             bar: [
               6,
               7,
               "8",
               %{__struct__: Z, qux: 9, quux: 10},
               %{
                 __struct__: Z,
                 qux: %{
                   foo: %{__struct__: Z, qux: 11, quux: %{__struct__: Z, qux: 12, quux: nil}}
                 },
                 quux: nil
               }
             ],
             biz: 123
           } == new_y

    for m <- [Y, Z] do
      :code.purge(m)
      :code.delete(m)
    end
  end
end
