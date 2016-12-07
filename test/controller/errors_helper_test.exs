defmodule TestExAdmin.ErrorsHelperTests do
  use ExUnit.Case
  alias ExAdmin.Helpers

  defmodule TestExAdmin.Contact do
    import Ecto.Changeset
    use Ecto.Schema

    schema "contacts" do
      field :first_name, :string, null: false
      many_to_many :phone_numbers, TestExAdmin.PhoneNumber, join_through: TestExAdmin.ContactPhoneNumber
      timestamps
    end

    @required_fields ~w(first_name)
    @optional_fields ~w()

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, @required_fields, @optional_fields)
      |> cast_assoc(:phone_numbers, required: false)
    end
  end

  defmodule TestExAdmin.ContactPhoneNumber do
    import Ecto.Changeset
    use Ecto.Schema

    schema "contacts_phone_numbers" do
      belongs_to :contact, TestExAdmin.Contact
      belongs_to :phone_number, TestExAdmin.PhoneNumber

      timestamps
    end

    @required_fields ~w(contact_id phone_number_id)
    @optional_fields ~w()

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, @required_fields, @optional_fields)
      |> assoc_constraint(:contact)
      |> assoc_constraint(:phone_number)
    end
  end

  defmodule TestExAdmin.PhoneNumber do
    import Ecto.Changeset
    use Ecto.Schema

    schema "phone_numbers" do
      field :number, :string, null: false
      field :label, :string, null: false

      has_many :contacts_phone_numbers, TestExAdmin.ContactPhoneNumber
      has_many :contacts, through: [:contacts_phone_numbers, :contact]

      timestamps
    end

    @required_fields ~w(number label)
    @optional_fields ~w()

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, @required_fields, @optional_fields)
      |> validate_required([:number, :label])
      |> validate_length(:number, min: 1, max: 255)
      |> validate_length(:label, min: 1, max: 255)
    end
  end

  test "simple errors" do
    params = %{}
    changeset = TestExAdmin.Contact.changeset(%TestExAdmin.Contact{}, params)

    errors = ExAdmin.ErrorsHelper.create_errors(changeset, TestExAdmin.Contact)
    assert changeset.valid? == false
    assert errors == [first_name: {"can't be blank", []}]
  end

  test "nested errors are squashed" do
    params = %{phone_numbers: %{"1483927542828": %{_destroy: "0", label: "Primary Phone",
                 number: nil}}}
    changeset = TestExAdmin.Contact.changeset(%TestExAdmin.Contact{}, params)

    errors = ExAdmin.ErrorsHelper.create_errors(changeset, TestExAdmin.Contact)
    assert changeset.valid? == false
    assert errors == [first_name: {"can't be blank", []}, phone_numbers_attributes_0_number: {"can't be blank", []}]
  end
end
