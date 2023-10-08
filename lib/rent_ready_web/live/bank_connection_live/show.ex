defmodule RentReadyWeb.BankConnectionLive.Show do
  use RentReadyWeb, :live_view

  alias RentReady.Banking

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bank_connection, Banking.get_user_bank_connection!(user, id))}
  end

  defp page_title(:show), do: "Show Bank connection"
end
