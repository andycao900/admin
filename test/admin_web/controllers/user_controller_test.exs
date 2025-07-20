defmodule AdminWeb.UserControllerTest do
  use AdminWeb.ConnCase

  import Admin.AccountsFixtures

  @create_attrs %{email: "some email"}
  @update_attrs %{email: "some updated email"}
  @invalid_attrs %{email: nil}

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/users")
      assert html_response(conn, 200) =~ "Listing Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/users/new")
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    import Mock

    test "redirects to show when data is valid and synced to Auth0", %{conn: conn} do
      with_mock Admin.Auth0.Auth0User, [
        get_user_by_email: fn _ -> {:error, :not_found} end,
        create_user: fn _ -> {:ok, %{}} end
      ] do
        conn = post(conn, ~p"/users", user: @create_attrs)

        assert %{id: id} = redirected_params(conn)
        assert redirected_to(conn) == ~p"/users/#{id}"
        assert get_flash(conn, :info) =~ "User created successfully and synced to Auth0."

        conn = get(conn, ~p"/users/#{id}")
        assert html_response(conn, 200) =~ "User #{id}"
      end
    end

    test "redirects to show when data is valid and Auth0 user already exists", %{conn: conn} do
      with_mock Admin.Auth0.Auth0User, [
        get_user_by_email: fn _ -> {:ok, %{}} end
      ] do
        conn = post(conn, ~p"/users", user: @create_attrs)

        assert %{id: id} = redirected_params(conn)
        assert redirected_to(conn) == ~p"/users/#{id}"
        assert get_flash(conn, :info) =~ "User created in DB. Auth0 user already exists."

        conn = get(conn, ~p"/users/#{id}")
        assert html_response(conn, 200) =~ "User #{id}"
      end
    end

    test "renders errors when DB user creation fails", %{conn: conn} do
      conn = post(conn, ~p"/users", user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New User"
      assert html_response(conn, 200) =~ "can't be blank"
    end

    test "renders errors and flash message when Auth0 user creation fails", %{conn: conn} do
      with_mock Admin.Auth0.Auth0User, [
        get_user_by_email: fn _ -> {:error, :not_found} end,
        create_user: fn _ -> {:error, "Auth0 create error"} end
      ] do
        conn = post(conn, ~p"/users", user: @create_attrs)
        assert html_response(conn, 200) =~ "New User"
        assert get_flash(conn, :error) =~ "Failed to create user in Auth0: \"Auth0 create error\""
      end
    end

    test "renders errors and flash message when Auth0 user lookup fails", %{conn: conn} do
      with_mock Admin.Auth0.Auth0User, [
        get_user_by_email: fn _ -> {:error, "Auth0 lookup error"} end
      ] do
        conn = post(conn, ~p"/users", user: @create_attrs)
        assert html_response(conn, 200) =~ "New User"
        assert get_flash(conn, :error) =~ "Failed to check Auth0 user: \"Auth0 lookup error\""
      end
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/#{user}/edit")
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/users/#{user}", user: @update_attrs)
      assert redirected_to(conn) == ~p"/users/#{user}"

      conn = get(conn, ~p"/users/#{user}")
      assert html_response(conn, 200) =~ "some updated email"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/users/#{user}", user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/users/#{user}")
      assert redirected_to(conn) == ~p"/users"

      assert_error_sent 404, fn ->
        get(conn, ~p"/users/#{user}")
      end
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
