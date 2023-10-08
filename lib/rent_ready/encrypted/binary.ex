defmodule RentReady.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: RentReady.Encrypted.Vault
end
