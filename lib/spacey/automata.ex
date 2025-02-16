defmodule Spacey.Automata do
  @moduledoc """
  Functions to visualize DFA automata using Graphvix.
  """

  alias Graphvix.Graph

  @doc """
  Visualizes a DFA and compiles the graph to a PNG file.

  ## Parameters
    - `states`: a list of states (e.g. `[0, 1, 2, 3]`)
    - `alphabet`: a list of symbols (e.g. `["a", "b"]`)
    - `transitions`: a list of lists representing the transition table. The element at row _i_ and column _j_ is the destination state for state _i_ on symbol at index _j_.
    - `initial_state`: the initial state (e.g. `0`)
    - `final_states`: a list (or set) of final states (e.g. `[1, 3]`)
    - `output_file` (optional): base name for the output files (default `"automata"`)

  ## Example

      iex> Spacey.Automata.visualize([0, 1, 2, 3], ["a", "b"], [[1, 2], [0, 3], [2, 3], [3, 3]], 0, [3])
  """
  def visualize(
        states,
        alphabet,
        transitions,
        initial_state,
        final_states,
        output_file \\ "automata"
      ) do
    # Convert final_states to a MapSet for faster membership checking.
    final_states = MapSet.new(final_states)

    graph = Graph.new()

    # Add nodes for each state.
    # We'll keep a map from state to its vertex id.
    {graph, vertex_map} =
      Enum.reduce(states, {graph, %{}}, fn state, {g, acc} ->
        # Use "doublecircle" for final states, "circle" otherwise.
        shape = if MapSet.member?(final_states, state), do: "doublecircle", else: "circle"
        label = to_string(state)
        {g, vertex_id} = Graph.add_vertex(g, label, shape: shape)
        {g, Map.put(acc, state, vertex_id)}
      end)

    # Add an invisible start vertex and connect it to the initial state.
    {graph, start_vertex} = Graph.add_vertex(graph, "", style: "invis")

    graph =
      Graph.add_edge(graph, start_vertex, Map.get(vertex_map, initial_state), style: "bold")
      |> elem(0)

    # Build a map of edges: keys are {from_state, to_state} pairs, and values are lists of symbols.
    edges =
      Enum.reduce(states, %{}, fn state, acc ->
        Enum.with_index(alphabet)
        |> Enum.reduce(acc, fn {symbol, index}, acc_inner ->
          dest = Enum.at(Enum.at(transitions, state), index)
          key = {state, dest}
          Map.update(acc_inner, key, [symbol], fn symbols -> [symbol | symbols] end)
        end)
      end)

    # Add edges to the graph, combining labels for multiple symbols.
    graph =
      Enum.reduce(edges, graph, fn {{from_state, to_state}, symbols}, g ->
        from_vertex = Map.get(vertex_map, from_state)
        to_vertex = Map.get(vertex_map, to_state)
        label = symbols |> Enum.reverse() |> Enum.join(", ")
        Graph.add_edge(g, from_vertex, to_vertex, label: label) |> elem(0)
      end)

    # Compile the graph to a PNG file (creates automata.dot and automata.png).
    Graph.compile(graph, output_file, :png)
    graph
  end
end
