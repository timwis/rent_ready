defmodule GoCardless do
  alias GoCardless.{
    AccessTokenContainer,
    AccountResponse,
    EndUserAgreementResponse,
    InstitutionResponse,
    RequisitionResponse,
    TransactionResponse
  }

  @callback new(opts :: []) :: Tesla.Client.t()
  def new(opts \\ []), do: impl().new(opts)

  @callback get_access_token(client :: Tesla.Client.t()) ::
              {:ok, access_token :: %AccessTokenContainer{}} | {:error, reasons :: String.t()}
  def get_access_token(client), do: impl().get_access_token(client)

  @callback get_institutions(client :: Tesla.Client.t()) ::
              {:ok, [%InstitutionResponse{}]} | {:error, reason :: String.t()}
  def get_institutions(client), do: impl().get_institutions(client)

  @callback create_end_user_agreement(
              client :: Tesla.Client.t(),
              institution_id :: String.t(),
              opts :: []
            ) ::
              {:ok, %EndUserAgreementResponse{}} | {:error, reason :: String.t()}
  def create_end_user_agreement(client, institution_id, opts \\ []),
    do: impl().create_end_user_agreement(client, institution_id, opts)

  @callback create_requisition(
              client :: Tesla.Client.t(),
              institution_id :: String.t(),
              redirect :: String.t(),
              opts :: []
            ) :: {:ok, %RequisitionResponse{}} | {:error, reason :: String.t()}

  def create_requisition(client, institution_id, redirect, opts \\ []),
    do: impl().create_requisition(client, institution_id, redirect, opts)

  @callback get_requisition(client :: Tesla.Client.t(), requisition_id :: String.t()) ::
              {:ok, %RequisitionResponse{}} | {:error, reason :: String.t()}
  def get_requisition(client, requisition_id), do: impl().get_requisition(client, requisition_id)

  @callback get_account_details(client :: Tesla.Client.t(), account_id :: String.t()) ::
              {:ok, %AccountResponse{}} | {:error, reason :: String.t()}
  def get_account_details(client, account_id), do: impl().get_account_details(client, account_id)

  @callback get_account_transactions(
              client :: Tesla.Client.t(),
              account_id :: String.t(),
              date_from :: DateTime.t(),
              date_to :: DateTime.t()
            ) ::
              {:ok, [%TransactionResponse{}]} | {:error, reason :: String.t()}
  def get_account_transactions(client, account_id, date_from, date_to),
    do: impl().get_account_transactions(client, account_id, date_from, date_to)

  defp impl(), do: Application.get_env(:rent_ready, :go_cardless_client, GoCardless.HttpClient)
end
