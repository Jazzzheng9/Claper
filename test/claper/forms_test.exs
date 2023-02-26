defmodule Claper.FormsTest do
  use Claper.DataCase

  alias Claper.Forms

  describe "forms" do
    alias Claper.Forms.Form

    import Claper.{FormsFixtures, PresentationsFixtures}

    @invalid_attrs %{title: nil}

    test "list_forms/1 returns all forms from a presentation" do
      presentation_file = presentation_file_fixture()
      form = form_fixture(%{presentation_file_id: presentation_file.id})

      assert Forms.list_forms(presentation_file.id) == [form]
    end

  end

end
