defmodule RentReady.BankingFixtures do
  def institution_fixture(attrs \\ %{}) do
    {:ok, institution} =
      attrs
      |> Enum.into(%{
        id: "SAMPLE_#{random_string()}",
        name: "Sample bank",
        logo: "https://rentready.app/logo.png"
      })
      |> RentReady.Banking.create_institution()

    institution
  end

  def bank_connection_fixture(user, attrs \\ %{}) do
    next_week = DateTime.add(DateTime.utc_now(), 7, :day)

    institution_id =
      if Map.has_key?(attrs, :institution_id) do
        attrs.institution_id
      else
        institution_fixture().id
      end

    {:ok, bank_connection} =
      attrs
      |> Enum.into(%{
        institution_id: institution_id,
        gc_agreement_id: UUID.uuid4(),
        gc_requisition_id: UUID.uuid4(),
        reference: UUID.uuid4(),
        link: "https://gocardless.rentready.app/start",
        status: :CR,
        expires_at: next_week
      })
      |> then(&RentReady.Banking.create_bank_connection(user, &1))

    bank_connection
  end

  defp random_string, do: for(_ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>)
end