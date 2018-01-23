defmodule FlowViz do
  use GenServer

  @moduledoc """
  A utility to track and graph throughput in a Flow workflow to help optimize performance.

  Inspired by http://teamon.eu/2016/measuring-visualizing-genstage-flow-with-gnuplot/

  ## Requirements

  Ensure that gnuplot is installed and x11 and wxt terminal are available.

  On ubuntu:

      sudo apt-get install gnuplot-x11

  and make sure you've got x11 going and DISPLAY is set.

  ## Usage ##

  ```elixir
  FlowViz.start_link([:links_parsed, :url_checked])
  FlowViz.plot()

  Flow.from_enumerable(...)
    |> FlowViz.checkpoint(:read)
    |> Flow.map(...)
    |> Flow.partition
    |> FlowViz.checkpoint(:something_else)

  FlowViz.done()
  ```

  ## Installation

  This package can be installed
  by adding `flow_viz` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:flow_viz, "~> 0.1.0"}
    ]
  end
  """

  @timeres :millisecond
  @plot_update_interval 1000 #milliseconds
  @disk_flush_interval  1000 #milliseconds
  @disk_flush_bytes     16384
  @plot_width           700
  @plot_height          500

  ## CLIENT API

  @doc ~S"""
    Start flow viz and open log files to store throughput information.
  """
  def start_link(scopes \\ []) do
    GenServer.start_link(__MODULE__, scopes, name: __MODULE__)
  end

  @doc ~S"""
    Closes all files and shuts down flowviz.
    Any open plot will remain visible.
  """
  def stop do
    done()
    GenServer.stop(__MODULE__)
  end

  @doc ~S"""
    Closes all files, generally in preparation for displaying a graph.
  """
  def done do
    GenServer.cast __MODULE__, :done
  end

  @doc ~S"""
    Increment counter for given scope by `n`, default 1.
    It's generally preferable to use &checkpoint/3

        FlowViz.incr(:parse_links)
        FlowViz.incr(:parse_links, 10)
  """
  def incr(scope, n \\ 1) do
    GenServer.cast __MODULE__, {:incr, scope, n}
  end

  @doc ~S"""
    For convenience, call checkpoint within a Flow to instrument it.
    This is preferred over calling incr directly.

        FlowViz.start_link([:links_parsed, :url_checked])

        Flow.from_enumerable(...)
           |> FlowViz.checkpoint(:read)
           |> Flow.map(...)
           |> Flow.partition
           |> FlowViz.checkpoint(:something_else)
  """
  def checkpoint(flow, scope, n \\ 1) do
    Flow.each(flow, fn _ -> incr(scope, n) end)
  end

  @doc ~S"""
    Renders a graph of current progress.
    If called before &done/1 the graph will replot every 1 second if there is new content.
  """
  def plot(xrange \\ nil) do
    GenServer.cast __MODULE__, {:plot, xrange}
  end

  ## CALLBACKS

  def init(scopes) do
    # open "progress-{scope}.log" file for every scope
    files = Enum.map(scopes, fn scope ->
      filename = log_path(scope)

      if File.exists?(filename) do
        File.rm!(filename)
      end

      File.touch!(filename)

      {scope, File.open!(filename, [:write, {:delayed_write, @disk_flush_bytes, @disk_flush_interval}])}
    end)

    # keep current counter for every scope
    counts = Enum.map(scopes, fn scope -> {scope, 0} end)

    # save current time
    time = :os.system_time(@timeres)

    # write first data point for every scope with current time and value 0
    # this helps to keep the graph starting nicely at (0,0) point
    Enum.each(files, fn {_, io} ->
      write(io, time, 0)
      write(io, time + 1, 0)
      :ok = :file.sync(io)
     end)

    {:ok, {time, files, counts, nil, 0}}
  end

  def handle_cast({:incr, scope, n}, {time, files, counts, plot, last_replot}) do
    # update counter
    {value, counts} = Keyword.get_and_update!(counts, scope, &({&1+n, &1+n}))

    # write new data point
    write(files[scope], time, value)

    now = :os.system_time(@timeres)

    if plot && (now - last_replot) > @plot_update_interval do
      Port.command(plot, "replot\n")
      {:noreply, {time, files, counts, plot, now}}
    else
      {:noreply, {time, files, counts, plot, last_replot}}
    end
  end

  def handle_cast(:done, {_time, files, _counts, _plot, _last_replot}) do
    Enum.each(files, fn {_, io} -> :ok = File.close(io) end)

    {:noreply, {:done, files}}
  end

  def handle_cast({:plot, xrange}, {:done, files} = state) do
    plot(xrange, files)
    {:noreply, state}
  end

  def handle_cast({:plot, xrange}, {time, files, counts, nil, _prev_replot}) do
    {:ok, plot} = plot(xrange, files)
    last_replot = :os.system_time(@timeres)
    {:noreply, {time, files, counts, plot, last_replot}}
  end

  defp plot(xrange, files) do
    plot_script = ~s"""
      set terminal wxt size #{@plot_width},#{@plot_height} enhanced font 'Arial,10' persist

      set title "Flow progress over time"
      set xlabel "Time (ms)"
      set ylabel "Items processed"
      set key top left

      #{plot_script_xrange(xrange)}
      #{plot_script_files(files)}
    """

    port = Port.open({:spawn, "gnuplot"}, [])
    Port.command(port, plot_script)
    {:ok, port}
  end

  defp plot_script_xrange(nil), do: ""
  defp plot_script_xrange(xrange), do: "set xrange [0:" <> Integer.to_string(xrange) <> "]"

  defp plot_script_files(files) do
    lines = files
      |> Enum.with_index
      |> Enum.map(fn {{scope, _file}, index} ->
          "\"#{log_path(scope)}\"  with lines  ls #{Integer.to_string(index + 1)} title \"#{plot_title(scope)}\""
        end)
      |> Enum.join(",\\\n")

    "plot #{lines}\n"
  end

  defp plot_title(scope) do
    scope
      |> Atom.to_string
      |> String.replace("_", " ")
  end

  defp log_path(scope), do: "progress-#{scope}.log"

  defp write(file, time, value) do
    time = :os.system_time(@timeres) - time
    IO.write(file, "#{time}\t#{value}\n")
  end
end
