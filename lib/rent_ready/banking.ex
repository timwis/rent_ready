defmodule RentReady.Banking do
  @moduledoc """
  The Banking context.
  """

  import Ecto.Query, warn: false
  alias RentReady.Repo

  alias GoCardless.{EndUserAgreementResponse, RequisitionResponse}
  alias RentReady.Banking.{BankAccount, BankConnection, Institution}
  alias RentReady.RowSelection
  alias RentReady.Accounts.User

  def list_institutions() do
    Repo.all(from(i in Institution, order_by: [asc: i.name]))
  end

  def get_institution!(id), do: Repo.get(Institution, id)

  def create_institution(attrs) do
    %Institution{}
    |> Institution.changeset(attrs)
    |> Repo.insert()
  end

  def sync_institutions() do
    access_token = get_access_token()

    {:ok, fetched_institutions} =
      GoCardless.new(access_token: access_token)
      |> GoCardless.get_institutions()

    now =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    validated_institutions =
      Enum.map(fetched_institutions, fn institution ->
        attrs = Institution.from_go_cardless(institution)

        %Institution{}
        |> Institution.changeset(attrs)
        |> Ecto.Changeset.apply_action!(:validate)
        |> Map.from_struct()
        |> Map.take([:id, :name, :logo, :transaction_days])
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    Repo.insert_all(Institution, validated_institutions,
      on_conflict: {:replace, [:name, :logo, :updated_at]},
      conflict_target: [:id]
    )

    # TODO: delete or deactivate records in the DB that are no longer present
    # in the remote source
  end

  def build_bank_connection_link(user, institution_id, redirect_url) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)
    connection_reference = UUID.uuid4()

    with institution <- get_institution!(institution_id),
         {:ok, agreement} <-
           GoCardless.create_end_user_agreement(
             client,
             institution_id,
             max_historical_days: institution.transaction_days || 90,
             access_scope: ["transactions", "details"]
           ),
         {:ok, requisition} <-
           GoCardless.create_requisition(
             client,
             institution_id,
             redirect_url,
             agreement: agreement.id,
             reference: connection_reference
           ),
         {:ok, _bank_connection} <- create_bank_connection(user, agreement, requisition) do
      {:ok, requisition.link}
    end
  end

  def sync_bank_connection(%BankConnection{} = bank_connection) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)

    with {:ok, requisition} <-
           GoCardless.get_requisition(client, bank_connection.gc_requisition_id),
         accounts <-
           Enum.map(requisition.accounts, fn account_id ->
             {:ok, account} = GoCardless.get_account_details(client, account_id)
             account
           end),
         {:ok, bank_connection} <-
           update_bank_connection(bank_connection, requisition, accounts) do
      {:ok, bank_connection}
    end
  end

  def list_user_bank_connections(%User{} = user) do
    BankConnection
    |> user_bank_connections_query(user)
    |> Repo.all()
    |> Repo.preload(:institution)
  end

  def get_user_bank_connection!(%User{} = user, id) do
    BankConnection
    |> user_bank_connections_query(user)
    |> Repo.get!(id)
    |> Repo.preload([:institution, :bank_accounts])
  end

  def get_user_bank_connection_by!(%User{} = user, clauses) do
    BankConnection
    |> user_bank_connections_query(user)
    |> Repo.get_by!(clauses)
    |> Repo.preload([:institution, :bank_accounts])
  end

  defp user_bank_connections_query(query, %User{id: user_id}) do
    from(bc in query, where: bc.user_id == ^user_id)
  end

  def create_bank_connection(
        %User{} = user,
        %EndUserAgreementResponse{} = agreement,
        %RequisitionResponse{} = requisition
      ) do
    attrs = BankConnection.from_go_cardless(agreement, requisition)
    create_bank_connection(user, attrs)
  end

  def create_bank_connection(%User{} = user, attrs) do
    %BankConnection{}
    |> BankConnection.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def update_bank_connection(
        %BankConnection{} = connection,
        %RequisitionResponse{} = requisition,
        accounts
      ) do
    attrs = BankConnection.from_go_cardless(requisition, accounts)
    update_bank_connection(connection, attrs)
  end

  def update_bank_connection(%BankConnection{} = connection, attrs) do
    connection
    |> Repo.preload(:bank_accounts)
    |> BankConnection.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_bank_connection(%BankConnection{} = bank_connection) do
    Repo.delete(bank_connection)
  end

  def get_user_bank_account!(%User{} = user, id) do
    BankAccount
    |> user_bank_accounts_query(user)
    |> Repo.get!(id)
    |> Repo.preload(bank_connection: :institution)
  end

  defp user_bank_accounts_query(query, %User{id: user_id}) do
    from(a in query,
      left_join: c in BankConnection,
      on: c.id == a.bank_connection_id,
      where: c.user_id == ^user_id
    )
  end

  def create_bank_account(%BankConnection{} = bank_connection, attrs) do
    %BankAccount{}
    |> BankAccount.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:bank_connection, bank_connection)
    |> Repo.insert()
  end

  def fetch_remote_transactions(%BankAccount{} = bank_account, from, to) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)

    with {:ok, transactions} <-
           GoCardless.get_account_transactions(client, bank_account.gc_id, from, to) do
      filtered_transactions = filter_relevant_transactions(transactions)
      {:ok, filtered_transactions}
    end
  end

  def change_transaction_selection(
        %RowSelection{} = row_selection \\ %RowSelection{},
        attrs \\ %{}
      ) do
    RowSelection.changeset(row_selection, attrs)
  end

  defp filter_relevant_transactions(transactions) do
    Enum.filter(transactions, fn txn ->
      txn.status == "booked" && Money.negative?(txn.transaction_amount)
    end)
  end

  defp get_access_token() do
    case Cachex.get(:banking_cache, "access_token") do
      {:ok, nil} ->
        {:ok, access_token_container} =
          GoCardless.new()
          |> GoCardless.get_access_token()

        expires_at = access_token_container.access_expires
        ttl = DateTime.diff(expires_at, DateTime.utc_now(), :millisecond)

        Cachex.put(:banking_cache, "access_token", access_token_container, ttl: ttl)
        access_token_container.access

      {:ok, access_token_container} ->
        access_token_container.access
    end
  end
end
