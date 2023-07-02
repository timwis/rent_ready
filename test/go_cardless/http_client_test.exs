defmodule GoCardless.HttpClientTest do
  alias GoCardless.EndUserAgreement
  use RentReady.DataCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Tesla.Mock
  import GoCardless.HttpClient

  alias GoCardless.{AccessTokenContainer, Institution, EndUserAgreement}

  describe "new/1" do
    test "adds bearer middleware if access_token provided" do
      client = new(access_token: "test_access_token")

      token =
        Tesla.Client.middleware(client)
        |> List.keyfind(Tesla.Middleware.BearerAuth, 0)
        |> elem(1)
        |> Keyword.get(:token)

      assert token == "test_access_token"
    end
  end

  describe "get_access_token/1" do
    test "constructs request and returns AccessTokenContainer" do
      mock(fn env ->
        body = Jason.decode!(env.body)
        assert Map.has_key?(body, "secret_id")
        assert Map.has_key?(body, "secret_key")

        json(%{
          access: "test_access",
          refresh: "test_refresh",
          access_expires: 1,
          refresh_expires: 2
        })
      end)

      client = new()
      %AccessTokenContainer{} = get_access_token(client)
    end
  end

  describe "get_institutions/1" do
    test "returns list of Institutions" do
      mock(fn _env ->
        json([
          %{
            "id" => "ACME",
            "name" => "ACME Bank",
            "bic" => "ACME123",
            "transactions_total_days" => "90",
            "countries" => ["GB"],
            "logo" => "https://example.com/logo.jpg"
          },
          %{
            "id" => "FOO",
            "name" => "FOO Bank",
            "bic" => "FOOBAR",
            "transactions_total_days" => "90",
            "countries" => ["GB"],
            "logo" => "https://example.com/logo2.jpg"
          }
        ])
      end)

      client = new(access_token: "test_access_token")

      [%Institution{} | _] = get_institutions(client)
    end
  end

  describe "create_end_user_agreement/3" do
    test "puts institution_id and valid opts into request body" do
      mock(fn env ->
        body = Jason.decode!(env.body)
        assert body["institution_id"] == "ACME"
        assert body["max_historical_days"] == 120
        assert body["access_valid_for_days"] == 30
        assert body["access_scope"] == ["details"]

        json(%{
          "id" => "uuid",
          "created" => "2023-06-28T00:00:00Z",
          "institution_id" => body["institution_id"],
          "max_historical_days" => body["max_historical_days"],
          "access_valid_for_days" => body["access_valid_for_days"],
          "access_scope" => body["access_scope"],
          "accepted" => nil
        })
      end)

      client = new(access_token: "test_access_token")
      opts = [max_historical_days: 120, access_valid_for_days: 30, access_scope: ["details"]]
      %EndUserAgreement{} = create_end_user_agreement(client, "ACME", opts)
    end
  end
end
