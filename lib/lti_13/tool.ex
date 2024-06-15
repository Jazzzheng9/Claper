defmodule Lti13.Tool do
  alias Lti13.DataProviders.EctoProvider

  @doc """
  Creates a new deployment.
  ## Examples
      iex> create_deployment(deployment)
      {:ok, %Lti_1p3.Tool.Deployment{}}
      iex> create_deployment(deployment)
      {:error, %Lti_1p3.DataProviderError{}}
  """
  def create_deployment(attrs),
    do: EctoProvider.create_deployment(attrs)

  @doc """
  Creates a new registration.
  ## Examples
      iex> create_registration(registration)
      {:ok, %Lti_1p3.Tool.Registration{}}
      iex> create_registration(registration)
      {:error, %Lti_1p3.DataProviderError{}}
  """
  def create_registration(attrs),
    do: EctoProvider.create_registration(attrs)

  @doc """
  Gets the registration with the given issuer and client_id.
  ## Examples
      iex> get_registration_by_issuer_client_id(issuer, client_id)
      %Registration{}
      iex> get_registration_by_issuer_client_id(issuer, client_id)
      nil
  """
  def get_registration_by_issuer_client_id(issuer, client_id),
    do: EctoProvider.get_registration_by_issuer_client_id(issuer, client_id)

  @doc """
  Gets the registration and deployment associated with the given issuer, client_id and deployment_id.
  ## Examples
      iex> get_registration_deployment(issuer, client_id, deployment_id)
      {%Registration{}, %Deployment{}}
      iex> get_registration_deployment(issuer, client_id, deployment_id)
      {nil, nil}
  """
  def get_registration_deployment(issuer, client_id, deployment_id),
    do: EctoProvider.get_registration_deployment(issuer, client_id, deployment_id)
end