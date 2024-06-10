defmodule Lti13.Tool.PlatformRole do
  @enforce_keys [:uri]
  defstruct [:id, :uri]

  @type t() :: %__MODULE__{
          id: integer(),
          uri: String.t()
        }
end
