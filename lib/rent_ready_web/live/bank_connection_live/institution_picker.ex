defmodule RentReadyWeb.BankConnectionLive.InstitutionPicker do
  use RentReadyWeb, :live_component

  alias RentReady.Banking

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Select your banking institution</:subtitle>
      </.header>

      <ul role="list" class="divide-y divide-gray-100">
        <li
          :for={{_id, institution} <- @streams.institutions}
          id={institution.id}
          class="flex justify-between gap-x-6 py-5 hover:cursor-pointer"
          phx-click="select_institution"
          phx-value-institution_id={institution.id}
        >
          <div class="flex min-w-0 gap-x-4">
            <img
              class="h-12 w-12 flex-none rounded-full bg-gray-50"
              src={institution.logo}
              alt={"#{institution.logo} logo"}
            />
            <div class="min-w-0 flex-auto">
              <p class="text-sm font-semibold leading-6 text-gray-900">
                <%= institution.name %>
              </p>
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, stream(socket, :institutions, Banking.list_institutions())}
  end
end
