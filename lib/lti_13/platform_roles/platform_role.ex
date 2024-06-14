defmodule Lti13.PlatformRoles.PlatformRole do
  @enforce_keys [:uri]
  defstruct [:id, :uri]

  @type t() :: %__MODULE__{
          id: integer(),
          uri: String.t()
        }
end
