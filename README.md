# Accounting with Emma

Learn accounting, with Emma! _Accounting with Emma_ is a small
fill-in-the-blanks game for the [TIC-80](https://tic.computer/) fantasy
computer. Help Emma record a ledger of financial transactions for her fledgling
art business, building up the balance sheet as you go.

Copyright © 2021 Dan Jacka

Released under the GNU General Public License version 3; see the file LICENSE.

## Getting started

You can play directly from your web browser on itch.io:

https://danjacka.itch.io/accounting-with-emma

Your role in the game is to help Emma balance each transaction in the ledger by
setting any missing values correctly.

Press the RIGHT arrow key to select the missing value, then use UP or DOWN to
increment or decrement the amount. Hold the Z key to increment or decrement in
larger units: $50 rather than $1.

Make the claims and resources amounts match, then press the LEFT arrow key to
move back to the ledger. Zing! Onto transaction two. The balance sheet shows the
total amounts including all of the previous transactions.

Read Emma's commentary at the bottom of the screen to understand what is being
captured in a transaction. You'll need those details to figure out what the
missing values are. If you're stuck, pay close attention to Emma's hints.

Sometimes it's useful to look back at previously completed transactions. To do
so, press LEFT until no value is selected, then UP and DOWN to navigate the
ledger.

## Use the source

You can edit the game's source code directly. Press ESC twice to access TIC-80's
code editor. _Accounting with Emma_ is written in
[Fennel](https://fennel-lang.org/). Try changing some values in the `puzzles`
data structure. To play the game with your changes, press ESC again to access
the TIC-80 console, then type "run".

You can also play and make changes locally. Get the repository from
https://github.com/danjacka/accounting-with-emma. Then with `make`, `entr` and
`tic80` on your path:

```
$ make
```

## Accounting basics

If you know nothing about accounting but want to learn through _Accounting with
Emma_, here's some basic help:

Keeping accounts helps businesses understand how they spend and receive money.
Emma could if she wanted keep a journal (or "ledger") of changes to her finances
like this:

> Spent $50 on renting a market stall

> Received $20 by selling a painting

That's useful, but prone to error. Real businesses record transactions as
adjustments to accounts, like this:

> Rent a market stall: $50 FROM the cash account, $50 TO the expenses account

> Sell painting: $20 TO the cash account, $20 FROM the sales account

Note that in each of these transactions, the total of the FROM and TO amounts is
zero. We say that the accounts _balance_. A total other than zero is invalid,
and indicates a mistake. Balancing transactions like this is called double-entry
accounting.

(You might ask why in the second example it's $20 FROM the sales account. Aren't
we adding TO our sales? FROM is correct. It's because there are two types of
accounts: resources and claims. Resources are what the business has - assets.
Claims are what the business owes - liabilities - and what the business is
worth - equity. Increasing a resource account amount is a TO (a credit);
increasing a claim account amount is a FROM (a debit).)

It's less common, but a transaction may include adjustments to _only_ resources
accounts or _only_ claims accounts, for example when trading one asset type
directly for another asset type. The usual rules apply: the total of the FROM
and TO amounts must equal zero.

The balance sheet shows the cumulative totals of accounts. Despite its
simplicity the balance sheet is a powerful tool for gauging a business's
financial health. A single transaction can have a dramatic effect. When you've
completed the final transaction, scroll back through the ledger and follow how
the balance sheet changes as Emma's business grows.

## Learning more

_Accounting with Emma_ illustrates how transactions are balanced movements
between accounts, but it doesn't cover common accounting concepts like tax and
depreciation. Where do you learn about those?

First, good news: those are part of balanced movements between accounts too!
Accounting is _buckets-of-numbers-that-add-up-to-zero_ all the way down. As you
learn about more advanced concepts, you should find that they fit into the model
you've learned through playing _Accounting with Emma_.

Looking for online help? I found the writing on
[accountingcoach.com](https://www.accountingcoach.com/) easy to follow. Written
by a single author, it's a cohesive view of accounting that provides lots of
detail without being overwhelming. There are tests and certifications if you
like that kind of thing.

Book-wise, I recommend "Accounting: A Very Short Introduction" by Christopher
Nobes. This neat little book covers just enough accounting mechanics (the same
basics as seen in _Accounting with Emma_, in fact the game uses the book's
terminology) and sets out accounting's place in the world: where it came from,
why it's useful, how companies think about it, etc.

If you are comfortable on the command-line, I recommend trying out
[Ledger](https://www.ledger-cli.org/), a plain text accounting system. In
particular I recommend reading Ledger's [excellent
manual](https://www.ledger-cli.org/3.0/doc/ledger3.html) and following the
examples therein. You'll see all the moving parts of a real-world accounting
system that fits naturally with your UNIX-wired brain.

## Credits

- Made by Dan Jacka.
- Based on a written version of Emma's story by Dan, Justin B, Kavi S, Kelly M,
  Lauren C, Ming L and Zac M.
- Inspired by Phil Hagelberg and Emma Bukacek's ["This Is My Mech"](http://technomancy.us/190) game.
- Uses Adigun A. Polack's [AAP-16 colour palette](https://lospec.com/palette-list/aap-16).
