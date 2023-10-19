defmodule RentReadyWeb.BankAccountLive.Show do
  use RentReadyWeb, :live_view

  alias RentReady.Banking

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
     |> assign_async(:transactions, fn ->
       case Banking.get_transactions(bank_account, from, to) do
         {:ok, transactions} -> {:ok, %{transactions: transactions}}
         {:error, reason} -> {:error, reason}
       end
     end)}
  end
end
