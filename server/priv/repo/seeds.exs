# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MaveMetrics.Repo.insert!(%MaveMetrics.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

key = MaveMetrics.Keys.get_key("HDsj3NfKQTNwn5Ix9g+cfQ==")

if is_nil(key) do
  MaveMetrics.Keys.create_key(%{"key" => "HDsj3NfKQTNwn5Ix9g+cfQ=="})
end
