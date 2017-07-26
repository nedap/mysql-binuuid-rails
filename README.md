[![Build Status](https://travis-ci.org/nedap/mysql-binuuid-rails.svg?branch=master)](https://travis-ci.org/nedap/mysql-binuuid-rails)

# mysql-binuuid-rails

`mysql-binuuid-rails` leverages the Attributes API of Rails 5 and lets you
define attributes of type UUID on your models. By doing so, you can store your
UUIDs as binary values in your database, and still be able to query using
the string representations since the database will take care of the
type conversion.

As the name suggests, it only supports MySQL. If you're on PostgreSQL, you
can use UUIDs the proper way already.

If you were to store a UUID of 32 characters (without the dashes) as text in
your database, it would cost you at least 32 bytes. And that only counts if
every character only requires 1 byte. But that completely depends on your
encoding. If every character requires 2 bytes, storing it would already cost
you 64 bytes. And that's a lot, if you think about the fact that a UUID is
only 128 bits.

Being 128 bits, a UUID first precisely in a column of 16 bytes. Though it won't
be really readable it sure saves up a lot of space and it's only 4x bigger
than a 32-bit integer, or 2x bigger than a 64-bit integer.

Not to mention the space you'll be saving when you create an index on the
column holding your UUID.

# Installation
You know the drill, add this line to your gemfile:

```
gem 'mysql-binuuid-rails'
```

# Usage
Using binary columns for UUIDs is very easy. There's only two steps you need to
perform which are described here.

## Adding the column to store your UUID
Suppose you have a model called `Book` to which you want to add a unique
identifier in the form of a UUID. First, make sure your database is able to
hold this attribute. So let's create a migration.

```
$ rails g migration AddUuidColumnToBooks
```

Open up the migration file and change it as you'd like:

```ruby
class AddUuidColumnToBooks < ActiveRecord::Migration[5.1]
  def change
    # 'uuid' is the column name, and 'binary' is the column type. You have to
    # specify it as a binary column yourself. And because we know that a UUID
    # takes up 16 bytes, we set can specify its limit.
    add_column :books, :uuid, :binary, limit: 16
  end
end
```

Perform the migration:

```
rails db:migrate
```

## Tell your model how to handle the binary UUID column
All you have to do now, is specify in your `Book` model how Rails should handle
the `uuid` column. Open up `app/models/book.rb` and simply add the following
single line:

```ruby
class Book < ApplicationRecord
  attribute :uuid, MySQLBinUUID::Type.new
end
```

# Contributing

To start coding on `mysql-binuuid-rails`, fork the project, clone it locally
and then run `bin/setup` to get up and running. If you want to fool around in
a console with the changes you made, run `bin/console`.

Bug reports and pull requests are welcome on GitHub at
https://github.com/nedap/mysql-binuuid-rails


# License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
