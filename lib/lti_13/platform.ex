defmodule Lti13.Platform do
  alias Lti13.DataProviders.EctoProvider

  @doc """
  Creates a new platform instance.
  ## Examples
      iex> create_platform_instance(platform_instance)
      {:ok, %Lti_1p3.Platform.PlatformInstance{}}
      iex> create_platform_instance(platform_instance)
      {:error, %Lti_1p3.DataProviderError{}}
  """
  def create_platform_instance(%Lti13.Platform.PlatformInstance{} = platform_instance),
    do: EctoProvider.create_platform_instance(platform_instance)
end
