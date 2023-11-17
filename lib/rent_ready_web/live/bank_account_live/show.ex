defmodule RentReadyWeb.BankAccountLive.Show do
  use RentReadyWeb, :live_view

  alias RentReady.Banking
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    bank_account = Banking.get_user_bank_account!(user, id)
    to = Date.utc_today()
    from = Date.add(to, -30)

    {:ok,
     socket
     |> assign(:page_title, "Show Bank account")
     |> assign(:bank_connection, bank_account.bank_connection)
     |> assign(:bank_account, bank_account)
     |> assign(:changeset, Banking.change_transaction_selection())
     |> stream(:transactions, [])
     |> assign(:transactions_status, AsyncResult.loading())
     |> start_async(:get_transactions, fn ->
       Banking.fetch_remote_transactions(bank_account, from, to)
     end)}
  end

  def handle_async(:get_transactions, {:ok, {:ok, transactions}}, socket) do
    %{transactions_status: transactions_status} = socket.assigns

    {:noreply,
     socket
     |> assign(:transactions_status, AsyncResult.ok(transactions_status, true))
     |> stream(:transactions, transactions)}
  end

  def handle_async(:get_transactions, {:ok, {:error, reason}}, socket) do
    handle_async(:get_transactions, {:exit, reason}, socket)
  end

  def handle_async(:get_transactions, {:exit, reason}, socket) do
    %{transactions_status: transactions_status} = socket.assigns

    {:noreply,
     assign(
       socket,
       :transactions_status,
       AsyncResult.failed(transactions_status, {:exit, reason})
     )}
  end

  @impl true
  def handle_event(
        "submit_transactions",
        %{"selected" => selected},
        socket
      ) do
    IO.inspect(selected)
    {:noreply, socket}
  end
end
