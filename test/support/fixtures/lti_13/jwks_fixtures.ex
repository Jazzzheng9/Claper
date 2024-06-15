defmodule Lti13.JwksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Claper.Forms` context.
  """

  @doc """
  Generate a form.
  """
  def jwk_fixture(attrs \\ %{}) do
    {:ok, jwk} =
      attrs
      |> Enum.into(%{
        pem: "some pem",
        typ: "some typ",
        alg: "some alg",
        kid: "some kid",
        use: "some use",
        active: true
      })
      |> Lti13.Jwks.create_jwk()

    jwk
  end
end