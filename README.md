# Restruct [![Hex Version](https://img.shields.io/hexpm/v/restruct.svg)](https://hex.pm/packages/restruct) [![Hex Docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/restruct/) [![CI Status](https://github.com/bjyoungblood/restruct/actions/workflows/elixir.yml/badge.svg)](https://github.com/bjyoungblood/restruct/actions/workflows/elixir.yml)

An Elixir library for ensuring structs match their current definition.

This is useful if you serialize structs using `:erlang.term_to_binary/1` or are
sending structs between nodes running different code versions.

## Installation

The package can be installed by adding `restruct` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:restruct, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/restruct>.
