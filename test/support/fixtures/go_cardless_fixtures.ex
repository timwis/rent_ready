defmodule GoCardless.Fixtures do
  alias GoCardless.{
    AccessTokenContainer,
    AccountResponse,
    EndUserAgreementResponse,
    InstitutionResponse,
    RequisitionResponse,
    TransactionResponse
  }

  def access_token_container_fixture(attrs \\ %{}) do
    now = DateTime.utc_now()

    attrs
    |> Enum.into(%{
      access: "test_access_token",
      access_expires: DateTime.add(now, 1, :day),
      refresh: "test_refresh_token",
      refresh_expires: DateTime.add(now, 7, :day)
    })
    |> then(&struct(AccessTokenContainer, &1))
  end

  def institution_response_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: "SAMPLE_#{random_string()}",
      name: "Sample Bank",
      bic: "SAMPLE_BANK",
      transaction_total_days: "540",
      countries: ["GB"],
      logo: "https://rentready.app/logo.png"
    })
    |> then(&struct(InstitutionResponse, &1))
  end

  def end_user_agreement_response_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: UUID.uuid4(),
      institution_id: "SAMPLE_#{random_string()}",
      created: DateTime.utc_now(),
      max_historical_days: 180,
      access_valid_for_days: 30,
      access_scope: [:details, :transactions],
      accepted: ""
    })
    |> then(&struct(EndUserAgreementResponse, &1))
  end

  def requisition_response_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: UUID.uuid4(),
      institution_id: "SAMPLE_#{random_string()}",
      created: DateTime.utc_now(),
      redirect: "https://rentready.app/redirect",
      status: "CR",
      reference: UUID.uuid4(),
      agreement: UUID.uuid4(),
      link: "https://gocardless.rentready.app/start",
      accounts: []
    })
    |> then(&struct(RequisitionResponse, &1))
  end

  def account_response_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: UUID.uuid4(),
      resource_id: random_string(),
      iban: random_string(),
      currency: "GBP",
      owner_name: "John Doe",
      name: "Bills",
      cash_account_type: "CACC",
      status: "enabled"
    })
    |> then(&struct(AccountResponse, &1))
  end

  def transaction_response_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      id: random_string(),
      status: "booked",
      booking_date: Date.utc_today(),
      value_date: Date.utc_today(),
      booking_date_time: DateTime.utc_now(),
      value_date_time: DateTime.utc_now(),
      transaction_amount: Money.new(-1000, :GBP),
      debtor_name: "Acme Markets",
      remittance_information_unstructured: "GROCERIES",
      internal_transaction_id: random_string()
    })
    |> then(&struct(TransactionResponse, &1))
  end

  defp random_string do
    for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
  end
end
