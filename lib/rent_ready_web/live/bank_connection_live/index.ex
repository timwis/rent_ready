defmodule RentReadyWeb.BankConnectionLive.Index do
  use RentReadyWeb, :live_view

  alias RentReady.Banking
  alias RentReady.Banking.BankConnection

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    {:ok, stream(socket, :bank_connections, Banking.list_user_bank_connections(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Bank connection")
    |> assign(:bank_connection, %BankConnection{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Bank connections")
    |> assign(:bank_connection, nil)
  end

  defp apply_action(socket, :authorised, %{"ref" => reference}) do
    user = socket.assigns.current_user
    bank_connection = Banking.get_user_bank_connection_by!(user, reference: reference)
    {:ok, _} = Banking.sync_bank_connection(bank_connection)
    redirect(socket, to: ~p"/bank_connections")
  end

  @impl true
  def handle_event("select_institution", %{"institution_id" => institution_id}, socket) do
    user = socket.assigns.current_user
    return_redirect_url = url(socket, ~p"/bank_connections/authorised")
    {:ok, link} = Banking.build_bank_connection_link(user, institution_id, return_redirect_url)
    {:reply, %{}, redirect(socket, external: link)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    bank_connection = Banking.get_user_bank_connection!(user, id)
    {:ok, _} = Banking.delete_bank_connection(bank_connection)

    {:noreply, stream_delete(socket, :bank_connections, bank_connection)}
  end
end
