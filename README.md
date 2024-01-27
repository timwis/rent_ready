# RentReady
Increase your chance of securing the flat you want by creating a tenant CV

RentReady is a web application built in Elixir using the Phoenix framework.

## Development
### Pre-requisites
First, make sure [elixir is installed][3].

### Environment variables
Second, you'll need to create an account with [GoCardless Bank Account Data][1] (formerly Nordigen, and different from a normal GoCardless account). This will allow you to generate a secret ID and secret key pair. RentReady expects these values as environment variables `GO_CARDLESS_SECRET_ID` and `GO_CARDLESS_SECRET_KEY`.

RentReady also expects a `CLOAK_SECRET_KEY` environment variable. You can generate this using the `iex` REPL and running:

```
iex> 32 |> :crypto.strong_rand_bytes() |> Base.encode64()
```

### Development server
Clone this repository, then, to start the web server:

* Run `mix setup` to install and setup dependencies
* Run `mix phx.server` to run the web server

### Caching the third-party API
Optionally, you can use a command-line tool like [json-caching-proxy][2] to cache responses from GoCardless/Nordigen during development:

```
npx json-caching-proxy -u https://bankaccountdata.gocardless.com/api/v2 -l
```

Just remember to update the GoCardless API endpoint in `lib/go_cardless/http_client.ex` to the proxy URL (e.g. `http://localhost:3000/api/v2`).

[1]: https://gocardless.com/bank-account-data/
[2]: https://www.npmjs.com/package/json-caching-proxy
[3]: https://elixir-lang.org/install.html
