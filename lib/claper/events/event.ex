defmodule Claper.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :uuid, :binary_id
    field :name, :string
    field :code, :string
    field :audience_peak, :integer, default: 1
    field :started_at, :naive_datetime
    field :expired_at, :naive_datetime

    field :no_file, :boolean, default: false, virtual: true

    has_many :posts, Claper.Posts.Post

    has_many :leaders, Claper.Events.ActivityLeader, on_replace: :delete

    has_one :presentation_file, Claper.Presentations.PresentationFile
    belongs_to :user, Claper.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :name,
      :code,
      :started_at,
      :expired_at,
      :audience_peak
    ])
    |> cast_assoc(:presentation_file)
    |> cast_assoc(:leaders)
    |> validate_required([:code])
  end

  def create_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :code, :user_id, :started_at, :no_file])
    |> cast_assoc(:presentation_file)
    |> cast_assoc(:leaders)
    |> validate_required([:code, :started_at])
    |> downcase_code
  end

  def downcase_code(changeset) do
    update_change(
      changeset,
      :code,
      &(&1 |> String.downcase() |> String.split(~r"[^\w\d]", trim: true) |> List.first())
    )
  end

  def update_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :code, :started_at, :expired_at, :audience_peak])
    |> cast_assoc(:presentation_file)
    |> cast_assoc(:leaders)
    |> validate_required([:code, :started_at])
    |> downcase_code
  end

  def restart_changeset(event) do
    expiry =
      NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.add(48 * 3600)

    change(event, expired_at: expiry)
  end

  def subscribe(event_id) do
    Phoenix.PubSub.subscribe(Claper.PubSub, "event:#{event_id}")
  end

  def started?(event) do
    NaiveDateTime.compare(NaiveDateTime.utc_now(), event.started_at) == :gt
  end

  def finished?(event) do
    event.expired_at && NaiveDateTime.compare(NaiveDateTime.utc_now(), event.expired_at) == :gt
  end
end
