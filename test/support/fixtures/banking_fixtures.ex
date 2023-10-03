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

  def agreement_fixture(user, attrs \\ %{}) do
    next_week = DateTime.add(DateTime.utc_now(), 7, :day)

    banking_institution_id =
      if Map.has_key?(attrs, :banking_institution_id) do
        attrs.banking_institution_id
      else
        institution_fixture().id
      end

    {:ok, agreement} =
      attrs
      |> Enum.into(%{
        external_id: UUID.uuid4(),
        expires_at: next_week,
        banking_institution_id: banking_institution_id
      })
      |> then(&RentReady.Banking.create_agreement(user, &1))

    agreement
  end

  def requisition_fixture(agreement, attrs \\ %{}) do
    {:ok, requisition} =
      attrs
      |> Enum.into(%{
        external_id: UUID.uuid4(),
        status: :CR,
        link: "https://gocardless.rentready.app/start",
        reference: UUID.uuid4()
      })
      |> then(&RentReady.Banking.create_requisition(agreement, &1))

    requisition
  end

  defp random_string, do: for(_ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>)
end
