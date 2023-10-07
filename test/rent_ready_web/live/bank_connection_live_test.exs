defmodule RentReadyWeb.BankConnectionLiveTest do
  use RentReadyWeb.ConnCase

  import Phoenix.LiveViewTest
  import RentReady.AccountsFixtures
  import RentReady.BankingFixtures

  defp create_user(_) do
    %{user: user_fixture()}
  end

  defp create_bank_connection(%{user: user}) do
    bank_connection = bank_connection_fixture(user)
    %{bank_connection: bank_connection}
  end

  describe "Index" do
    setup [:create_user, :create_bank_connection]

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/bank_connections")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "lists all bank_connections", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/bank_connections")

      assert html =~ "Listing Bank connections"
    end

    test "deletes bank_connection in listing", %{
      conn: conn,
      bank_connection: bank_connection,
      user: user
    } do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/bank_connections")

      assert index_live
             |> element("#bank_connections-#{bank_connection.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#bank_connections-#{bank_connection.id}")
    end
  end
end
