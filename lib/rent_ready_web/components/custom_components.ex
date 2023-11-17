defmodule RentReadyWeb.CustomComponents do
  use Phoenix.Component

  import RentReadyWeb.Gettext

  @doc ~S"""
  Renders the transactions table with selectable rows and stackable columns.

  ## Examples

      <.transaction_table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.transactions_table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :stacked, :boolean
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def transactions_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div
      class="px-4 sm:px-0"
      x-data="{
        selected_rows: [],
        toggle(id) {
          if (this.selected_rows.includes(id)) {
            this.selected_rows = this.selected_rows.filter(row => row !== id)
          }
          else { this.selected_rows.push(id) }
        }
      }"
    >
      <div
        class="fixed bottom-0 left-0 right-0 h-20 z-10 bg-zinc-100 bg-opacity-75 flex items-center justify-end pr-4"
        x-show="selected_rows.length > 0"
      >
        <button
          type="submit"
          class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          Submit <span x-text="selected_rows.length"></span> transactions
        </button>
      </div>
      <table class="min-w-full mt-11">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th class="relative px-7 sm:w-12 sm:px-6"></th>
            <th
              :for={col <- @col}
              class={["p-0 pr-6 pb-4 font-normal", col[:stacked] && "hidden lg:table-cell"]}
            >
              <%= col[:label] %>
            </th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            x-data={@row_id && "{ id: '#{@row_id.(row)}' }"}
            class="group hover:bg-zinc-50"
            x-bind:class="selected_rows.includes(id) && 'bg-gray-50'"
          >
            <td class="relative px-7 sm:w-12 sm:px-6">
              <div
                x-show="selected_rows.includes(id)"
                class="absolute inset-y-0 left-0 w-0.5 bg-indigo-600"
              >
              </div>
              <input
                type="checkbox"
                class="absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
                x-bind:value="id"
                x-model="selected_rows"
                name="selected[]"
              />
            </td>
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              x-on:click="toggle(id)"
              class={[
                "relative p-0 hover:cursor-pointer",
                col[:stacked] && "hidden lg:table-cell"
              ]}
            >
              <div class="block py-4 pr-6">
                <span
                  class="relative"
                  x-bind:class={
                    i == 0 &&
                      "selected_rows.includes(id) ? 'text-indigo-600 font-semibold' : 'text-zinc-900 font-semibold'"
                  }
                >
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list inside a table cell, used for displaying
  stacked columns.

  ## Examples

      <.stack>
        <:item title="Email"><%= @user.email %></:item>
        <:item title="Registration date"><%= @user.registration_date %></:item>
      </.stack>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def stack(assigns) do
    ~H"""
    <dl class="font-normal lg:hidden">
      <div :for={item <- @item}>
        <dt class="sr-only"><%= item.title %></dt>
        <dd class="mt-1 truncate text-gray-700"><%= render_slot(item) %></dd>
      </div>
    </dl>
    """
  end
end
