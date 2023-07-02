defmodule GoCardless do
  alias GoCardless.{
    AccessTokenContainer,
    Account,
    EndUserAgreement,
    Institution,
    Requisition,
    Transaction
  }

  @implementation Application.compile_env(:rent_ready, :go_cardless_client, GoCardless.HttpClient)

  @callback new(opts :: []) :: Tesla.Client.t()
  defdelegate new(opts \\ []), to: @implementation

  @callback get_access_token(client :: Tesla.Client.t()) ::
              {:ok, access_token :: %AccessTokenContainer{}} | {:error, reasons :: String.t()}
  defdelegate get_access_token(client), to: @implementation

  @callback get_institutions(client :: Tesla.Client.t()) ::
              {:ok, [%Institution{}]} | {:error, reason :: String.t()}
  defdelegate get_institutions(client), to: @implementation

  @callback create_end_user_agreement(
              client :: Tesla.Client.t(),
              institution_id :: String.t(),
              opts :: []
            ) ::
              {:ok, %EndUserAgreement{}} | {:error, reason :: String.t()}
  defdelegate create_end_user_agreement(client, institution_id, opts \\ []), to: @implementation

  @callback create_requisition(
              client :: Tesla.Client.t(),
              institution_id :: String.t(),
              redirect :: String.t(),
              opts :: []
            ) :: {:ok, %Requisition{}} | {:error, reason :: String.t()}

  defdelegate create_requisition(client, institution_id, redirect, opts \\ []),
    to: @implementation

  @callback get_requisition(client :: Tesla.Client.t(), requisition_id :: String.t()) ::
              {:ok, %Requisition{}} | {:error, reason :: String.t()}
  defdelegate get_requisition(client, requisition_id), to: @implementation

  @callback get_account_details(client :: Tesla.Client.t(), account_id :: String.t()) ::
              {:ok, %Account{}} | {:error, reason :: String.t()}
  defdelegate get_account_details(client, account_id), to: @implementation

  @callback get_account_transactions(client :: Tesla.Client.t(), account_id :: String.t()) ::
              {:ok, [%Transaction{}]} | {:error, reason :: String.t()}
  defdelegate get_account_transactions(client, account_id), to: @implementation
end
