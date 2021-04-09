[![Maintainability](https://api.codeclimate.com/v1/badges/7bcb6538e7666bc37f9a/maintainability)](https://codeclimate.com/github/nedap/mysql-binuuid-rails/maintainability) [![Build Status](https://nedap.semaphoreci.com/badges/mysql-binuuid-rails/branches/master.svg?style=shields)](https://nedap.semaphoreci.com/projects/mysql-binuuid-rails)

# mysql-binuuid-rails

`mysql-binuuid-rails` lets you define attributes of a UUID type on your models
by leveraging the Attributes API that has been available since Rails 5. By doing
so, you can store your UUIDs as binary values in your database, and still be
able to query using the string representations since the database will take care
of the type conversion.

As the name suggests, it only supports MySQL. If you're on PostgreSQL, you
can use UUIDs the proper way already.

If you were to store a UUID of 32 characters (without the dashes) as text in
your database, it would cost you at least 32 bytes. And that only counts if
every character only requires 1 byte. But that completely depends on your
encoding. If every character requires 2 bytes, storing it would already cost
you 64 bytes. And that's a lot, if you think about the fact that a UUID is
only 128 bits.

Being 128 bits, a UUID fits precisely in a column of 16 bytes. Though it won't
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

# Migrating from ActiveUUID

There's a couple of things you need to take into consideration when you're
migrating from ActiveUUID to `mysql-binuuid-rails`.

## Replace `include ActiveUUID::UUID` in your models

In your models where you did `include ActiveUUID::UUID`, you now have to
specify the attribute which is a UUID instead:

```ruby
class Book < ApplicationRecord
  attribute :uuid, MySQLBinUUID::Type.new
end
```


## No `uuid` column in database migrations

ActiveUUID comes with a neat column type that you can use in migrations. Since
`mysql-binuuid-rails` does not, you will have to change all migrations in which
you leveraged on that migration column if you want your migrations to keep
working for new setups.

The idea behind *not* providing a `uuid` type for columnns in migrations is
that you are aware of what the actual type of the column is you're creating,
and that it is not hidden magic.

It's pretty simple:


```ruby
# Anywhere where you did this in your migrations...

create_table :books do |t|
  t.uuid :reference, ...
end

# ..you should change these kinds of lines into the kind described
# below. It's what ActiveUUID  did for you, but what you now have
# to do yourself.

create_table :books do |t|
  t.binary :reference, limit: 16, ...
end
```

## No UUIDTools

ActiveUUID comes with [UUIDTools](https://github.com/sporkmonger/uuidtools).
`mysql-binuuid-rails` does not. When you retrieve a UUID typed attribute from
a model when using ActiveUUID, the result is a `UUIDTools::UUID` object. When
you retrieve a UUID typed attribute from a model when using
`mysql-binuuid-rails`, you just get a `String` of 36 characters (it includes
the dashes).

Migrating shouldn't be that difficult though. `UUIDTools::UUID` implements
`#to_s`, which returns precisely the same as `mysql-binuuid-rails` returns
by default. But it's good to be aware of this in case you're running into
weirdness.


# Known issues

  * With Rails 5.0 in combination with uniqueness validations, ActiveRecord generates a wrong query. The `x` in front of the queried value, which casts the value to the proper data type, is missing.


# Contributing

To start coding on `mysql-binuuid-rails`, fork the project, clone it locally
and then run `bin/setup` to get up and running. If you want to fool around in
a console with the changes you made, run `bin/console`.

Bug reports and pull requests are welcome on GitHub at
https://github.com/nedap/mysql-binuuid-rails

## Testing

Continuous integration / automated tests run [on Semaphore](https://nedap.semaphoreci.com/projects/mysql-binuuid-rails).
Tests are run against the latest patch version of every minor ActiveRecord release
since 5.0, as well as *every* patch version of the latest minor version.

Run tests yourself to verify everything is still working:

```
$ bundle exec rake
```


## Contributors

See [CONTRIBUTORS.md](CONTRIBUTORS.md).


# License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
