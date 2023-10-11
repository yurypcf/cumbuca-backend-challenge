# CUMBUCA Backend Challenge

A webserver whose objective is to persist User Account in database.

Those persisted User Account must be able to:

- Sign in
- Visualize User Account attributes (balance, opening balance, etc)
- Transfer balance amount
- Reverse a succesfull transfer
- Collect Transactions data filtered by start and end date

## Summary

- [Setup](#setup)
- [Functionalities](#functionalities)
  - [Creating a User Account](#creating-a-user-account)
  - [Signin in](#signin-in)
  - [Retrieving your User Account data](#retrieving-your-user-account-data)
  - [Transfering to another account](#transfering-to-another-account)
  - [Checking transactions](#checking-transactions)
  - [Reversing a transaction](#reversing-a-transaction)

## Setup

This project is using `Docker` and `docker compose` to ease the setup steps.

**First step** is using docker compose up to setup the `database` and `api` running

```console
  docker compose up
```

This should setup the PostgreSQL database and our API. If `docker compose up` were ran under dettached mode, use `docker compose logs` to see if API and database is running OK. It should look something like this


![image](https://github.com/yurypcf/cumbuca-backend-challenge/assets/15652497/4ce5d5af-0279-4fb2-a7bb-67bb04ced931)

If the project is running ok, you can run the project **unit tests** and **integration tests** by typing

```console
  docker compose run -e "RAILS_ENV=test" api bundle exec rails test
```

## Functionalities

### Creating a User Account

```console
curl -H "Content-Type: application/json" -d '{"user_account": {"name": "Alucard", "last_name": "Tepes", "document_number": "45564121376", "opening_balance": 25000, "password": "123456"}}' localhost:3000/user_accounts
```

Response should be 201, CREATED

**note**: opening balance is defined in cents

### Signin in

Two params must be provided to sign in: registered document number and password.

```console
curl -H "Content-Type: application/json" -d '{"document_number":"45564121376", "password": "123456"}' localhost:3000/user_accounts/sign_in
```

Response should be 200 with User Account token body along with the expiry time of the token (set to 20 minutes).

**Copy this token** as every other route from now on, validates provided Token

### Retrieving your User Account data

```console
curl -H "Authorization: Bearer TOKENHERE" localhost:3000/user_accounts/me
```

Response should be 200 with the created User Account data.

### Transfering to another account

First, we need another account to transfer to. Create another one using the first functionality

```console
curl -H "Content-Type: application/json" -d '{"user_account": {"name": "Dracula", "last_name": "Tepes", "document_number": "84566082032", "opening_balance": 125000, "password": "123456"}}' localhost:3000/user_accounts
```

Now, lets test the transaction route to be able to transfer from Alucard to Dracula.

Alucard needs to send a POST request with parameters `receiver_document_number` that is the receiver registered document number (in this case, his father, Dracula).

The second parameter is `amount`. The amount he wishes to transfer, in this case 2000 (20 reais, probably a blood vial he owes his father).

```console
curl -H "Authorization: Bearer TOKENHERE" -H "Content-Type: application/json" -d '{"receiver_document_number": "84566082032", "amount": 2000}' localhost:3000/transactions/create -v
```

Response should be the `transaction_id` registered in database.

### Checking transactions

Alucard wants to check transaction he just made now.

He can access the report endpoint by using his `token`, a `start_date` and `end_date` to filter.

```console
curl -H "Authorization: Bearer TOKENHERE" -H "Content-Type: application/json" -d '{"start_date": "2023-10-11", "end_date": "2023-10-11"}' localhost:3000/transactions
```

Response should be transacations array, containing the transaction he just made about now.

![image](https://github.com/yurypcf/cumbuca-backend-challenge/assets/15652497/1496543e-a1ac-4e8e-8bcb-faccf573f696)


### Reversing a transaction

Well, Dracula didn't meant to charge his son for blood vials, so now Alucard wants his money back.

Alucard can reverse his transaction using the `transaction_id` and his `token` on `/transactions/reverse` POST route:

```console
curl -H "Authorization: Bearer TOKENHERE" -H "Content-Type: application/json" -d '{"transaction": { "transaction_id": "bd1cfa6f-8e85-4471-9169-17a4900ac226" } }' localhost:3000/transactions/reverse
```

Response should be a `reversed_transaction_id`

`transaction_id` can be retrieved anytime from the `/transactions` route.

Checking for user account transactions report again, the transaction now must be in `reversal` type.

![image](https://github.com/yurypcf/cumbuca-backend-challenge/assets/15652497/4dc932bb-d921-4ce0-bacd-74bb9400d0b0)

Which means she CAN'T be reversed anymore.
