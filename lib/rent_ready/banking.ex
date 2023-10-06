defmodule RentReady.Banking do
  @moduledoc """
  The Banking context.
  """

  import Ecto.Query, warn: false
  alias RentReady.Repo

  alias GoCardless.{EndUserAgreementResponse, RequisitionResponse}
  alias RentReady.Banking.{BankConnection, Institution}
  alias RentReady.Accounts.User

  def list_institutions() do
    Repo.all(Institution)
  end

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

    validated_institutions =
      Enum.map(fetched_institutions, fn institution ->
        now =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

        Institution.changeset(%Institution{}, Map.from_struct(institution))

        %Institution{}
        |> Institution.changeset(Map.from_struct(institution))
        |> Ecto.Changeset.apply_action!(:validate)
        |> Map.from_struct()
        |> Map.take([:id, :name, :logo])
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

    with {:ok, agreement} <-
           GoCardless.create_end_user_agreement(
             client,
             institution_id,
             max_historical_days: 730,
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

  def sync_bank_connection(reference) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)

    with bank_connection <- get_bank_connection_by_reference!(reference),
         {:ok, requisition} <-
           GoCardless.get_requisition(client, bank_connection.gc_requisition_id),
         {:ok, bank_connection} <-
           update_bank_connection(bank_connection, requisition) do
      {:ok, bank_connection}
    end
  end

  def list_bank_connections(%User{} = user) do
    Repo.all(from a in BankConnection, where: a.user_id == ^user.id)
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

  def get_bank_connection_by_reference!(reference),
    do: Repo.get_by!(BankConnection, reference: reference)

  def update_bank_connection(
        %BankConnection{} = connection,
        %RequisitionResponse{} = requisition
      ) do
    attrs = BankConnection.from_go_cardless(requisition)
    update_bank_connection(connection, attrs)
  end

  def update_bank_connection(%BankConnection{} = connection, attrs) do
    connection
    |> BankConnection.update_changeset(attrs)
    |> Repo.update()
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
