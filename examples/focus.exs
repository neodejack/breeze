{:ok, handler_config} = :logger.get_handler_config(:default)

updated_config =
  handler_config
  |> Map.update!(:config, fn config ->
    Map.put(config, :type, :standard_error)
  end)

:ok = :logger.remove_handler(:default)
:ok = :logger.add_handler(:default, :logger_std_h, updated_config)

defmodule Breeze.List do
  def init(children, last_state) do
    %{values: Enum.map(children, &(&1.value)), selected: last_state[:selected]}
  end

  def handle_event(_, %{"key" => "ArrowDown"}, %{values: values} = state) do
    index = Enum.find_index(values, &(&1 == state.selected))
    value = if index, do: Enum.at(values, index + 1) || hd(values), else: hd(values)
    {:noreply, %{state | selected: value}}
  end

  def handle_event(_, %{"key" => "ArrowUp"}, %{values: values} = state) do
    index = Enum.find_index(values, &(&1 == state.selected))
    first = hd(Enum.reverse(values))
    value = if index, do: Enum.at(values, index - 1) || first, else: first
    {:noreply, %{state | selected: value}}
  end

  def handle_event(_, %{"key" => "q"}, state) do
    {{:change, %{value: state.selected}}, state}
  end

  def handle_event(_, _, state), do: {:noreply, state}

  def handle_modifiers(flags, state) do
    if state.selected == Keyword.get(flags, :value) do
      [selected: true]
    else
      []
    end
  end
end

defmodule Focus do
  use Breeze.View

  def mount(opts, term) do
    term = Map.put_new(term, :receiver, Keyword.fetch!(opts, :receiver))

    term = %{term | focused: "l1"}
    {:ok, term}
  end

  def render(assigns) do
    ~H"""
    <box id="lol">
      <box style="inline border focus:border-3" focusable id="base">
        <.list :for={id <- ["l1", "l2", "l3", "l4", "l5"]} br-change="selected-event" id={id}>
          <:item value="hello">Hello</:item>
          <:item value="world">World</:item>
          <:item value="foo">Foo</:item>
        </.list>
      </box>

      <box style="inline border focus:border-3" focusable id="basel">
        <.list :for={id <- ["ll1", "ll2", "ll3", "ll4", "ll5"]} id={id}>
          <:item value="hello">Hello</:item>
          <:item value="world">World</:item>
          <:item value="foo">Foo</:item>
        </.list>
      </box>
      <box>Press tab/shift-tab to change focus</box>
    </box>
    """
  end

  attr(:id, :string, required: true)
  attr(:rest, :global)

  slot :item do
    attr(:value, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <box focusable style="border focus:border-3" implicit={Breeze.List} id={@id} {@rest}>
        <box
          :for={item <- @item}
          value={item.value}
          style="selected:bg-24 selected:text-0 focus:selected:text-7 focus:selected:bg-4"
        >{render_slot(item, %{})}</box>
    </box>
    """

  end

  def handle_info(_, term) do
    {:noreply, term}
  end

  def handle_event("selected-event", %{value: value}, term) do
    send(term.receiver, {:selected, value})
    {:noreply, term}
  end

  def handle_event(_, _, term) do
    {:noreply, term}
  end

end


{:ok, ui} = Breeze.Server.start_link(view: Focus, hide_cursor: false, start_opts: [receiver: self()])


receive do
  {:selected, value} ->
    GenServer.stop(ui)
    File.write("receive_file", "receievd from freeze: #{value}\n", [:append])
    IO.puts("receievd from freeze: #{value}")
end

