defmodule RentReady.Banking do
  @moduledoc """
  The Banking context.
  """

  import Ecto.Query, warn: false
  alias RentReady.Repo

  alias GoCardless.{EndUserAgreementResponse, RequisitionResponse}
  alias RentReady.Banking.{Agreement, Institution, Requisition}
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

  def build_requisition_link(user, institution_id, redirect_url) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)
    requisition_reference = UUID.uuid4()

    with {:ok, remote_agreement} <-
           GoCardless.create_end_user_agreement(
             client,
             institution_id,
             max_historical_days: 730,
             access_scope: ["transactions", "details"]
           ),
         {:ok, local_agreement} <- create_agreement(user, remote_agreement),
         {:ok, remote_requisition} <-
           GoCardless.create_requisition(
             client,
             institution_id,
             redirect_url,
             agreement: remote_agreement.id,
             reference: requisition_reference
           ),
         {:ok, _local_requisition} <- create_requisition(local_agreement, remote_requisition) do
      {:ok, remote_requisition.link}
    end
  end

  def sync_requisition(reference) do
    access_token = get_access_token()
    client = GoCardless.new(access_token: access_token)

    with local_requisition <- get_requisition_by_reference!(reference),
         {:ok, remote_requisition} <-
           GoCardless.get_requisition(client, local_requisition.external_id),
         {:ok, local_requisition} <-
           update_requisition(local_requisition, remote_requisition) do
      {:ok, local_requisition}
    end
  end

  def list_agreements(%User{} = user) do
    Repo.all(from a in Agreement, where: a.user_id == ^user.id)
    |> Repo.preload(:banking_requisitions)
  end

  def create_agreement(%User{} = user, %EndUserAgreementResponse{} = remote_agreement) do
    attrs = Agreement.from_go_cardless(remote_agreement)
    create_agreement(user, attrs)
  end

  def create_agreement(%User{} = user, attrs) do
    %Agreement{}
    |> Agreement.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def get_requisition_by_reference!(reference),
    do: Repo.get_by!(Requisition, reference: reference)

  def create_requisition(%Agreement{} = agreement, %RequisitionResponse{} = remote_requisition) do
    attrs = Requisition.from_go_cardless(remote_requisition)
    create_requisition(agreement, attrs)
  end

  def create_requisition(%Agreement{} = agreement, attrs) do
    %Requisition{}
    |> Requisition.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:banking_agreement, agreement)
    |> Repo.insert()
  end

  def update_requisition(
        %Requisition{} = requisition,
        %RequisitionResponse{} = remote_requisition
      ) do
    attrs = Requisition.from_go_cardless(remote_requisition)
    update_requisition(requisition, attrs)
  end

  def update_requisition(%Requisition{} = requisition, attrs) do
    requisition
    |> Requisition.update_changeset(attrs)
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
