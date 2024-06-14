defmodule Lti13.ContextRoles.ContextRole do
  @enforce_keys [:uri]
  defstruct [:id, :uri]

  @type t() :: %__MODULE__{
          id: integer(),
          uri: String.t()
        }
end
