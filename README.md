# FlowViz

A utility to track and graph throughput in a Flow workflow to help optimize performance.

Inspired by http://teamon.eu/2016/measuring-visualizing-genstage-flow-with-gnuplot/

## Usage

    FlowViz.start_link([:links_parsed, :url_checked])
    FlowViz.plot()

    Flow.from_enumerable(...)
      |> FlowViz.checkpoint(:read)
      |> Flow.map(...)
      |> Flow.partition
      |> FlowViz.checkpoint(:something_else)

    FlowViz.done()

## Installation

This package can be installed
by adding `flow_viz` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flow_viz, "~> 0.1.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/flow_viz](https://hexdocs.pm/flow_viz).

