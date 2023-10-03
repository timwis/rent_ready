defmodule RentReady.BankingTest do
  use RentReady.DataCase, async: true

  import Mox
  import GoCardless.Fixtures
  import RentReady.BankingFixtures
  import RentReady.AccountsFixtures

  alias RentReady.Banking
  alias GoCardless.HttpClient

  require IEx

  setup :verify_on_exit!

  describe "sync_institutions/0" do
    setup [:stub_new, :stub_get_access_token]

    test "inserts when table is empty" do
      MockGoCardless
      |> expect(:get_institutions, fn _ ->
        {:ok, [institution_response_fixture(), institution_response_fixture()]}
      end)

      Banking.sync_institutions()

      institutions = Banking.list_institutions()
      assert length(institutions) == 2
    end

    test "updates when institutions present" do
      institution_fixtures = [
        institution_response_fixture(),
        institution_response_fixture()
      ]

      Banking.create_institution(%{
        id: hd(institution_fixtures).id,
        name: "Old name",
        logo: "Old logo"
      })

      MockGoCardless
      |> expect(:get_institutions, fn _ -> {:ok, institution_fixtures} end)

      Banking.sync_institutions()

      institutions = Banking.list_institutions()
      assert length(institutions) == 2

      updated_institution =
        Enum.find(institutions, fn institution ->
          institution.id == hd(institution_fixtures).id
        end)

      assert updated_institution.name == hd(institution_fixtures).name
    end

    # test "maintains original inserted_at value" do end
    # test "soft deletes institutions no longer present in remote api" do end
  end

  describe "build_requisition_link/1" do
    setup [:stub_new, :stub_get_access_token, :seed_institution]

    test "creates Agreement and Requisition in database", context do
      institution_id = context.institution.id

      MockGoCardless
      |> expect(:create_end_user_agreement, fn _, _, _ ->
        {:ok, end_user_agreement_response_fixture(institution_id: institution_id)}
      end)
      |> expect(:create_requisition, fn _, _, _, _ ->
        {:ok, requisition_response_fixture()}
      end)

      user = user_fixture()

      {:ok, _link} =
        Banking.build_requisition_link(user, institution_id, "https://rentready.app/redirect")

      agreements = Banking.list_agreements(user)

      assert length(agreements) == 1
      assert length(hd(agreements).banking_requisitions) == 1
    end
  end

  describe "sync_requisition/1" do
    setup [
      :stub_new,
      :stub_get_access_token,
      :seed_institution,
      :seed_user,
      :seed_agreement,
      :seed_requisition
    ]

    test "updates status, but not link", context do
      reference = context.requisition.reference
      original_link_value = context.requisition.link

      MockGoCardless
      |> expect(:get_requisition, fn _, _ ->
        {:ok, requisition_response_fixture(status: "LN", link: "new link")}
      end)

      {:ok, _updated_requisition} = Banking.sync_requisition(reference)

      requisition = Banking.get_requisition_by_reference!(reference)
      assert requisition.status == :LN
      assert requisition.link == original_link_value
    end
  end

  defp stub_new(_context) do
    stub(MockGoCardless, :new, fn opts -> HttpClient.new(opts) end)
    :ok
  end

  defp stub_get_access_token(_context) do
    stub(MockGoCardless, :get_access_token, fn _ -> {:ok, access_token_container_fixture()} end)
    :ok
  end

  defp seed_institution(_context) do
    {:ok, institution: institution_fixture()}
  end

  def seed_user(_context) do
    {:ok, user: user_fixture()}
  end

  def seed_agreement(context) do
    user = context.user
    institution_id = context.institution.id
    {:ok, agreement: agreement_fixture(user, %{banking_institution_id: institution_id})}
  end

  defp seed_requisition(context) do
    agreement = context.agreement
    {:ok, requisition: requisition_fixture(agreement)}
  end
end
