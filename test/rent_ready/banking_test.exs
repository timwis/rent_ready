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

  describe "build_bank_connection_link/3" do
    setup [:stub_new, :stub_get_access_token, :seed_institution]

    test "creates BankConnection in the database", context do
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
        Banking.build_bank_connection_link(user, institution_id, "https://rentready.app/redirect")

      bank_connections = Banking.list_user_bank_connections(user)

      assert length(bank_connections) == 1
    end
  end

  describe "sync_bank_connection/1" do
    setup [
      :stub_new,
      :stub_get_access_token,
      :seed_institution,
      :seed_user,
      :seed_bank_connection
    ]

    test "updates status, but not link", context do
      user = context.user
      bank_connection = context.bank_connection
      original_link_value = context.bank_connection.link

      MockGoCardless
      |> expect(:get_requisition, fn _, _ ->
        {:ok, requisition_response_fixture(status: "LN", link: "new link")}
      end)

      {:ok, _updated_bank_connection} = Banking.sync_bank_connection(bank_connection)

      bank_connection = Banking.get_user_bank_connection!(user, bank_connection.id)
      assert bank_connection.status == :LN
      assert bank_connection.link == original_link_value
    end

    test "fetches and creates associated bank_account records", %{
      user: user,
      bank_connection: bank_connection
    } do
      MockGoCardless
      |> expect(:get_requisition, fn _, _ ->
        {:ok,
         requisition_response_fixture(
           status: "LN",
           link: "new link",
           accounts: [UUID.uuid4(), UUID.uuid4()]
         )}
      end)
      |> expect(:get_account_details, 2, fn _, account_id ->
        {:ok, account_response_fixture(resource_id: account_id)}
      end)

      {:ok, _updated_bank_connection} = Banking.sync_bank_connection(bank_connection)

      bank_connection = Banking.get_user_bank_connection!(user, bank_connection.id)
      assert length(bank_connection.bank_accounts) == 2
      assert hd(bank_connection.bank_accounts).name != nil
    end
  end

  describe "fetch_remote_transactions/3" do
    setup [
      :stub_new,
      :stub_get_access_token,
      :seed_institution,
      :seed_user,
      :seed_bank_connection,
      :seed_bank_account
    ]

    test "filters out income and non-booked transactions", context do
      transaction_fixtures = [
        transaction_response_fixture(
          status: "booked",
          transaction_amount: Money.new(-1000, :GBP)
        ),
        transaction_response_fixture(
          status: "pending",
          transaction_amount: Money.new(-2000, :GBP)
        ),
        transaction_response_fixture(
          status: "booked",
          transaction_amount: Money.new(500, :GBP)
        )
      ]

      MockGoCardless
      |> expect(:get_account_transactions, fn _, _, _, _ -> {:ok, transaction_fixtures} end)

      bank_account = context.bank_account
      to = Date.utc_today()
      from = Date.add(to, -30)

      assert {:ok, transactions} = Banking.fetch_remote_transactions(bank_account, from, to)
      assert length(transactions) == 1
      assert Money.equals?(hd(transactions).transaction_amount, Money.new(-1000, :GBP))
    end
  end

  describe "list_user_transactions/1" do
    setup [
      :stub_new,
      :stub_get_access_token,
      :seed_institution,
      :seed_user,
      :seed_bank_connection,
      :seed_bank_account
    ]

    test "lists transactions across user's bank accounts", context do
      transaction_fixture(context.bank_account)

      _other_bank_account_transaction =
        bank_account_fixture(context.bank_connection)
        |> transaction_fixture()

      transactions = Banking.list_user_transactions(context.user)

      assert length(transactions) == 2
    end

    test "excludes transactions belonging to other users", context do
      expected_transaction = transaction_fixture(context.bank_account)

      _other_users_transaction =
        user_fixture()
        |> bank_connection_fixture()
        |> bank_account_fixture()
        |> transaction_fixture()

      transactions = Banking.list_user_transactions(context.user)

      assert length(transactions) == 1
      assert hd(transactions).id == expected_transaction.id
    end
  end

  describe "fetch_and_save_remote_transactions/4" do
    setup [
      :stub_new,
      :stub_get_access_token,
      :seed_institution,
      :seed_user,
      :seed_bank_connection,
      :seed_bank_account
    ]

    test "fetches and saves transactions", context do
      transaction_fixtures = repeat(&transaction_response_fixture/0, 5)

      MockGoCardless
      |> expect(:get_account_transactions, fn _, _, _, _ -> {:ok, transaction_fixtures} end)

      bank_account = context.bank_account
      to = Date.utc_today()
      from = Date.add(to, -30)

      transaction_ids =
        transaction_fixtures
        |> Enum.take_random(2)
        |> Enum.map(& &1.internal_transaction_id)

      assert {:ok, _operations} =
               Banking.fetch_and_save_remote_transactions(bank_account, from, to, transaction_ids)

      transactions = Banking.list_user_transactions(context.user)
      assert length(transactions) == 2
    end

    test "returns error if a transaction id is not found in new fetch", context do
      transaction_fixtures = repeat(&transaction_response_fixture/0, 5)

      MockGoCardless
      |> expect(:get_account_transactions, fn _, _, _, _ -> {:ok, transaction_fixtures} end)

      bank_account = context.bank_account
      to = Date.utc_today()
      from = Date.add(to, -30)

      transaction_ids =
        transaction_fixtures
        |> Enum.take_random(2)
        |> Enum.map(& &1.internal_transaction_id)
        |> List.insert_at(-1, "unknown_id")

      assert {:error, {:not_found, "unknown_id"}} =
               Banking.fetch_and_save_remote_transactions(bank_account, from, to, transaction_ids)
    end

    test "returns error if a transaction is already saved", context do
      transaction_fixtures = repeat(&transaction_response_fixture/0, 5)

      MockGoCardless
      |> expect(:get_account_transactions, 2, fn _, _, _, _ -> {:ok, transaction_fixtures} end)

      bank_account = context.bank_account
      to = Date.utc_today()
      from = Date.add(to, -30)

      transaction_ids = Enum.map(transaction_fixtures, & &1.internal_transaction_id)

      already_saved_txn_id = Enum.at(transaction_ids, 1)
      Banking.fetch_and_save_remote_transactions(bank_account, from, to, [already_saved_txn_id])

      assert {:error, {:transaction, already_saved_txn_id}, %Ecto.Changeset{}, _changes_so_far} =
        Banking.fetch_and_save_remote_transactions(bank_account, from, to, transaction_ids)
    end

    # Either because too many transaction ids are provided in the request, or
    # because the new ids, in combination with the existing saves, are too many
    @tag :skip
    test "returns error if user transaction save count is exceeded"
  end

  describe "crud functions" do
    setup [:seed_institution, :seed_user, :seed_bank_connection]

    test "list_user_bank_connections/1 excludes other users' bank connections", context do
      {:ok, user: user} = seed_user(context)
      {:ok, bank_connection: user_bank_connection} = seed_bank_connection(%{context | user: user})

      result = Banking.list_user_bank_connections(user)
      assert length(result) == 1
      assert hd(result).id == user_bank_connection.id
    end

    test "get_user_bank_connection!/2 and get_user_bank_connection_by!/2 both raise when accessing another user's bank connection",
         context do
      other_user_bank_connection = context.bank_connection
      {:ok, user: user} = seed_user(context)
      {:ok, bank_connection: user_bank_connection} = seed_bank_connection(%{context | user: user})

      assert _bank_connection = Banking.get_user_bank_connection!(user, user_bank_connection.id)

      assert _bank_connection =
               Banking.get_user_bank_connection_by!(user,
                 reference: user_bank_connection.reference
               )

      assert_raise Ecto.NoResultsError, fn ->
        Banking.get_user_bank_connection!(user, other_user_bank_connection.id)
      end

      assert_raise Ecto.NoResultsError, fn ->
        Banking.get_user_bank_connection_by!(user,
          reference: other_user_bank_connection.reference
        )
      end
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

  defp seed_bank_connection(context) do
    user = context.user
    institution_id = context.institution.id
    {:ok, bank_connection: bank_connection_fixture(user, %{institution_id: institution_id})}
  end

  defp seed_bank_account(context) do
    bank_connection = context.bank_connection
    {:ok, bank_account: bank_account_fixture(bank_connection)}
  end

  defp repeat(fun, times), do: Enum.map(1..times, fn _ -> fun.() end)
end
