defmodule Admin.AccountsTest do
  use Admin.DataCase

  alias Admin.Accounts

  describe "users" do
    alias Admin.Accounts.User

    import Admin.AccountsFixtures

    @invalid_attrs %{email: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "some email"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "some email"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{email: "some updated email"}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.email == "some updated email"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "get_user_by_criteria/1 returns {:ok, user} when user is found" do
      user = user_fixture()
      assert {:ok, ^user} = Accounts.get_user_by_criteria(email: user.email)
    end

    test "get_user_by_criteria/1 returns {:error, :not_found} when user is not found" do
      assert {:error, :not_found} = Accounts.get_user_by_criteria(email: "nonexistent@example.com")
    end

    describe "create_user_with_auth0/1" do
      import Mock

      test "creates user in DB and Auth0 when both succeed" do
        valid_attrs = %{email: "new_user@example.com", password: "password123"}

        with_mock Admin.Auth0.Auth0User, [
          get_user_by_email: fn _ -> {:error, :not_found} end,
          create_user: fn _ -> {:ok, %{}} end
        ] do
          assert {:ok, %{db_user: %User{}, auth0_check_and_create: :created}} = Accounts.create_user_with_auth0(valid_attrs)
          assert Accounts.get_user_by_criteria(email: "new_user@example.com") == {:ok, Accounts.get_user_by_criteria(email: "new_user@example.com") |> elem(1)}
        end
      end

      test "creates user in DB and returns :already_exists if Auth0 user already exists" do
        valid_attrs = %{email: "existing_auth0_user@example.com", password: "password123"}

        with_mock Admin.Auth0.Auth0User, [
          get_user_by_email: fn _ -> {:ok, %{}} end
        ] do
          assert {:ok, %{db_user: %User{}, auth0_check_and_create: :already_exists}} = Accounts.create_user_with_auth0(valid_attrs)
          assert Accounts.get_user_by_criteria(email: "existing_auth0_user@example.com") == {:ok, Accounts.get_user_by_criteria(email: "existing_auth0_user@example.com") |> elem(1)}
        end
      end

      test "returns error if DB user creation fails" do
        invalid_attrs = %{email: nil} # Invalid email to cause DB creation failure

        with_mock Admin.Auth0.Auth0User, [
          get_user_by_email: fn _ -> {:error, :not_found} end,
          create_user: fn _ -> {:ok, %{}} end
        ] do
          assert {:error, :db_user, %Ecto.Changeset{}, _} = Accounts.create_user_with_auth0(invalid_attrs)
        end
      end

      test "returns error if Auth0 user creation fails" do
        valid_attrs = %{email: "auth0_fail@example.com", password: "password123"}

        with_mock Admin.Auth0.Auth0User, [
          get_user_by_email: fn _ -> {:error, :not_found} end,
          create_user: fn _ -> {:error, "Auth0 error"} end
        ] do
          assert {:error, :auth0_check_and_create, {:auth0_create_failed, "Auth0 error"}, _} = Accounts.create_user_with_auth0(valid_attrs)
          # Ensure DB user is rolled back
          assert Accounts.get_user_by_criteria(email: "auth0_fail@example.com") == {:error, :not_found}
        end
      end

      test "returns error if Auth0 lookup fails" do
        valid_attrs = %{email: "auth0_lookup_fail@example.com", password: "password123"}

        with_mock Admin.Auth0.Auth0User, [
          get_user_by_email: fn _ -> {:error, "Lookup error"} end
        ] do
          assert {:error, :auth0_check_and_create, {:auth0_lookup_failed, "Lookup error"}, _} = Accounts.create_user_with_auth0(valid_attrs)
          # Ensure DB user is rolled back
          assert Accounts.get_user_by_criteria(email: "auth0_lookup_fail@example.com") == {:error, :not_found}
        end
      end
    end
  end
end
