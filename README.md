# FlowViz

A utility to track and graph throughput in a Flow workflow to help optimize performance.

Just annotate your Flow with checkpoints and watch the graphs flow in!

![screenshot](https://i.imgur.com/E5kGBng.png)

Inspired by http://teamon.eu/2016/measuring-visualizing-genstage-flow-with-gnuplot/

## Requirements

Ensure that gnuplot is installed and x11 and wxt terminal are available.

On ubuntu:

    sudo apt-get install gnuplot-x11

and make sure you've got x11 going and DISPLAY is set.

## Usage

    FlowViz.start_link([:links_parsed, :url_checked])
    FlowViz.plot()

    Flow.from_enumerable(...)
      |> FlowViz.checkpoint(:links_parsed)
      |> Flow.map(...)
      |> Flow.partition
      |> FlowViz.checkpoint(:url_checked)

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

