defmodule GoCardless.HttpClient do
  alias Tesla.Env

  alias GoCardless.{
    AccessTokenContainer,
    AccountResponse,
    BalanceResponse,
    EndUserAgreementResponse,
    InstitutionResponse,
    RequisitionResponse,
    TransactionResponse
  }

  @country "gb"

  @middleware [
    {Tesla.Middleware.BaseUrl, "https://bankaccountdata.gocardless.com/api/v2"},
    Tesla.Middleware.JSON,
    Tesla.Middleware.Logger,
    {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]}
  ]

  def new(opts \\ []) do
    middleware =
      @middleware
      |> append_if(opts[:access_token], {Tesla.Middleware.BearerAuth, token: opts[:access_token]})

    middleware = middleware ++ Keyword.get(opts, :middleware, [])

    Tesla.client(middleware)
  end

  def get_access_token(client) do
    request_body =
      get_config()
      |> Keyword.take([:secret_id, :secret_key])
      |> Map.new()

    with {:ok, response} <- Tesla.post(client, "/token/new/", request_body),
         %Env{status: 200, body: response_body} <- response do
      {:ok, AccessTokenContainer.new(response_body)}
    end
  end

  def get_institutions(client) do
    with {:ok, response} <- Tesla.get(client, "/institutions/", query: [country: @country]),
         %Env{status: 200, body: response_body} <- response do
      {:ok, Enum.map(response_body, &InstitutionResponse.new/1)}
    end
  end

  def create_end_user_agreement(client, institution_id, opts \\ []) do
    request_body =
      opts
      |> Keyword.take([:max_historical_days, :access_valid_for_days, :access_scope])
      |> Map.new()
      |> Map.put(:institution_id, institution_id)

    with {:ok, response} <- Tesla.post(client, "/agreements/enduser/", request_body),
         %Env{status: status, body: response_body} when status in 200..299 <- response do
      {:ok, EndUserAgreementResponse.new(response_body)}
    end
  end

  # TODO: Should we use %CreateRequestionRequest{} and %CreateRequisitionResponse{} ?
  def create_requisition(client, institution_id, redirect, opts \\ []) do
    request_body =
      opts
      |> Keyword.take([:reference, :agreement, :user_language])
      |> Map.new()
      |> Map.put(:institution_id, institution_id)
      |> Map.put(:redirect, redirect)

    with {:ok, response} <- Tesla.post(client, "/requisitions/", request_body),
         %Env{status: status, body: response_body} when status in 200..299 <- response do
      {:ok, RequisitionResponse.new(response_body)}
    end
  end

  def get_requisition(client, requisition_id) do
    with {:ok, response} <- Tesla.get(client, "/requisitions/#{requisition_id}/"),
         %Env{status: 200, body: response_body} <- response do
      {:ok, RequisitionResponse.new(response_body)}
    end
  end

  def get_account_details(client, account_id) do
    with {:ok, response} <- Tesla.get(client, "/accounts/#{account_id}/details/"),
         %Env{status: 200, body: response_body} <- response do
      {:ok, AccountResponse.new(response_body["account"])}
    end
  end

  def get_account_transactions(client, account_id) do
    with {:ok, response} <- Tesla.get(client, "/accounts/#{account_id}/transactions/"),
         %Env{status: 200, body: response_body} <- response do
      {:ok, Enum.map(response_body, &TransactionResponse.new/1)}
    end
  end

  def get_balances(client, account_id) do
    with {:ok, response} <- Tesla.get(client, "/accounts/#{account_id}/transactions/"),
         %Env{status: 200, body: response_body} <- response,
         %{"balances" => balances} <- response_body do
      {:ok, Enum.map(balances, &BalanceResponse.new/1)}
    end
  end

  defp get_config(overrides \\ []) do
    Application.fetch_env!(:rent_ready, GoCardless)
    |> Keyword.merge(overrides)
  end

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end
