defmodule Lti13.DataProviders.EctoProviderTest do
  use Lti13.Test.TestCase
  # doctest Lti1p3EctoProvider

  alias Lti13.DataProviders.EctoProvider

  describe "data provider" do
    test "create and get active jwk" do
      %{private_key: private_key} = Lti_1p3.KeyGenerator.generate_key_pair()

      jwk = %Lti_1p3.Jwk{
        pem: private_key,
        typ: "JWT",
        alg: "RS256",
        kid: UUID.uuid4(),
        active: true
      }

      assert {:ok, %Lti_1p3.Jwk{pem: ^private_key, active: true}} = Lti13.Jwks.create_jwk(jwk)
      assert {:ok, %Lti_1p3.Jwk{pem: ^private_key, active: true}} = Lti13.Jwks.get_active_jwk()
    end

    test "create and get all jwks" do
      {:ok, active_jwk} = EctoProvider.get_active_jwk()
      %{private_key: private_key} = Lti_1p3.KeyGenerator.generate_key_pair()

      jwk1 = %Lti_1p3.Jwk{
        pem: private_key,
        typ: "JWT",
        alg: "RS256",
        kid: UUID.uuid4(),
        active: false
      }

      jwk2 = %Lti_1p3.Jwk{
        pem: private_key,
        typ: "JWT",
        alg: "RS256",
        kid: UUID.uuid4(),
        active: true
      }

      jwk3 = %Lti_1p3.Jwk{
        pem: private_key,
        typ: "JWT",
        alg: "RS256",
        kid: UUID.uuid4(),
        active: true
      }

      assert {:ok, %Lti_1p3.Jwk{}} = EctoProvider.create_jwk(jwk1)
      assert {:ok, %Lti_1p3.Jwk{}} = EctoProvider.create_jwk(jwk2)
      assert {:ok, %Lti_1p3.Jwk{}} = EctoProvider.create_jwk(jwk3)

      assert EctoProvider.get_all_jwks() |> Enum.map(&Map.get(&1, :kid)) == [
               active_jwk.kid,
               jwk1.kid,
               jwk2.kid,
               jwk3.kid
             ]
    end

    test "create and get nonce" do
      nonce = %Lti_1p3.Nonce{
        value: "some value",
        domain: "some domain"
      }

      assert {:ok, %Lti_1p3.Nonce{value: "some value", domain: "some domain"}} =
               EctoProvider.create_nonce(nonce)

      assert %Lti_1p3.Nonce{value: "some value", domain: "some domain"} =
               EctoProvider.get_nonce(nonce.value, nonce.domain)
    end

    test "create and get nonce without a domain" do
      nonce = %Lti_1p3.Nonce{
        value: "some value"
      }

      assert {:ok, %Lti_1p3.Nonce{value: "some value", domain: nil}} =
               EctoProvider.create_nonce(nonce)

      assert %Lti_1p3.Nonce{value: "some value", domain: nil} =
               EctoProvider.get_nonce(nonce.value, nonce.domain)
    end

    test "delete expired nonces" do
      {:ok, nonce} =
        EctoProvider.create_nonce(%Lti_1p3.Nonce{
          value: "some value",
          domain: "some domain"
        })

      # verify the nonce exists before cleanup
      assert EctoProvider.get_nonce(nonce.value, nonce.domain) == nonce

      # fake the nonce was created a day + 1 hour ago
      a_day_before = Timex.now() |> Timex.subtract(Timex.Duration.from_hours(25))

      struct(EctoProvider.Nonce, Map.from_struct(nonce))
      |> Ecto.Changeset.cast(%{inserted_at: a_day_before}, [:inserted_at])
      |> Repo.update!()

      # delete expired nonces
      EctoProvider.delete_expired_nonces()

      # no more nonce
      assert EctoProvider.get_nonce(nonce.value, nonce.domain) == nil
    end
  end

  describe "tool data provider" do
    test "create and get registration by issuer client id" do
      jwk = jwk_fixture()

      registration = %Lti_1p3.Tool.Registration{
        issuer: "some issuer",
        client_id: "some client_id",
        key_set_url: "some key_set_url",
        auth_token_url: "some auth_token_url",
        auth_login_url: "some auth_login_url",
        auth_server: "some auth_server",
        tool_jwk_id: jwk.id
      }

      assert {:ok, %Lti_1p3.Tool.Registration{issuer: "some issuer", client_id: "some client_id"}} =
               EctoProvider.create_registration(registration)

      assert %Lti_1p3.Tool.Registration{issuer: "some issuer", client_id: "some client_id"} =
               EctoProvider.get_registration_by_issuer_client_id("some issuer", "some client_id")
    end

    test "create and get deployment and registration by deployment_id" do
      jwk = jwk_fixture()
      registration = registration_fixture(%{tool_jwk_id: jwk.id})

      deployment_id = "some deployment_id"
      issuer = "https://lti-ri.imsglobal.org"
      client_id = "12345"
      registration_id = registration.id

      deployment = %Lti_1p3.Tool.Deployment{
        deployment_id: deployment_id,
        registration_id: registration_id
      }

      assert {:ok,
              %Lti_1p3.Tool.Deployment{
                deployment_id: ^deployment_id,
                registration_id: ^registration_id
              }} = EctoProvider.create_deployment(deployment)

      assert %Lti_1p3.Tool.Deployment{
               deployment_id: ^deployment_id,
               registration_id: ^registration_id
             } = EctoProvider.get_deployment(registration, deployment_id)

      assert {^registration,
              %Lti_1p3.Tool.Deployment{
                deployment_id: ^deployment_id,
                registration_id: ^registration_id
              }} = EctoProvider.get_registration_deployment(issuer, client_id, deployment_id)
    end

    test "get jwk by registration" do
      jwk = jwk_fixture()
      jwk_id = jwk.id
      registration = registration_fixture(%{tool_jwk_id: jwk_id})

      assert %Lti_1p3.Jwk{id: ^jwk_id} = EctoProvider.get_jwk_by_registration(registration)
    end
  end

  describe "platform data provider" do
    test "create and get platform instance by client id" do
      platform_instance = %Lti_1p3.Platform.PlatformInstance{
        client_id: "some client_id",
        custom_params: "some custom_params",
        description: "some description",
        keyset_url: "some keyset_url",
        login_url: "some login_url",
        name: "some name",
        redirect_uris: "some redirect_uris",
        target_link_uri: "some target_link_uri"
      }

      assert {:ok,
              %Lti_1p3.Platform.PlatformInstance{client_id: "some client_id", name: "some name"}} =
               EctoProvider.create_platform_instance(platform_instance)

      assert %Lti_1p3.Platform.PlatformInstance{client_id: "some client_id", name: "some name"} =
               EctoProvider.get_platform_instance_by_client_id("some client_id")
    end

    test "create and get login hint by value" do
      login_hint = %Lti_1p3.Platform.LoginHint{
        value: "some value",
        session_user_id: 1,
        context: "some context"
      }

      assert {:ok, %Lti_1p3.Platform.LoginHint{value: "some value"}} =
               EctoProvider.create_login_hint(login_hint)

      assert %Lti_1p3.Platform.LoginHint{value: "some value"} =
               EctoProvider.get_login_hint_by_value("some value")
    end

    test "delete expired login hints" do
      {:ok, login_hint} =
        EctoProvider.create_login_hint(%Lti_1p3.Platform.LoginHint{
          value: "some value",
          session_user_id: 1,
          context: "some context"
        })

      # verify the login hint exists before cleanup
      assert EctoProvider.get_login_hint_by_value(login_hint.value) == login_hint

      # fake the login hint was created a day + 1 hour ago
      a_day_before = Timex.now() |> Timex.subtract(Timex.Duration.from_hours(25))

      struct(EctoProvider.LoginHint, Map.from_struct(login_hint))
      |> Ecto.Changeset.cast(%{inserted_at: a_day_before}, [:inserted_at])
      |> Repo.update!()

      # delete expired login hints
      EctoProvider.delete_expired_login_hints()

      # no more login hint
      assert EctoProvider.get_login_hint_by_value(login_hint.value) == nil
    end
  end
end
