[![CI](https://github.com/nedap/mysql-binuuid-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/nedap/mysql-binuuid-rails/actions/workflows/ci.yml) [![Maintainability](https://api.codeclimate.com/v1/badges/7bcb6538e7666bc37f9a/maintainability)](https://codeclimate.com/github/nedap/mysql-binuuid-rails/maintainability)


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

## Invalid Values

By default, this will raise an exception if an invalid value is attempted to be stored.
However, the PostgreSQL driver nils invalid UUID values.
To get PG-friendly behavior, pass in the option `:nil_invalid_values => true` when creating the attribute.

Additionally, as a convenience function, you can add the following to `ApplicationRecord` to get parity between PG and MySQL:

```
def self.uuid_fields(*fields)
	if ActiveRecord::Base.connection.adapter_name.downcase.starts_with?("mysql")
		fields.each do |fld|
			attribute fld, MySQLBinUUID::Type.new(:nil_invalid_values => true)
		end
	end
end
```

Then, in your models, just begin them by marking the fields which are UUIDs.

## UUID Type in migrations

To get a UUID type in a migration, add the following to your initializers (Rails 7 specific):

```
require "active_record"
require "active_record/connection_adapters/mysql2_adapter"
require "active_record/type_caster/map"

module ActiveRecord
  module ConnectionAdapters
    module MySQL
      module ColumnMethods
        def uuid(*args, **options)
          # http://dba.stackexchange.com/questions/904/mysql-data-type-for-128-bit-integers
          # http://dev.mysql.com/doc/refman/5.7/en/binary-varbinary.html
          args.each { |name| column(name, "varbinary(16)", **options.merge(limit: 16)) }
        end
      end
      module SchemaStatements
        def type_to_sql(type, limit: nil, precision: nil, scale: nil, size: limit_to_size(limit, type), unsigned: nil, **)
          if type.to_s == "uuid"
            return "varbinary(16)"
          else
            super
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:uuid] = {:name => "varbinary", :limit => 16}
```

# Contributing
To start coding on `mysql-binuuid-rails`, fork the project, clone it locally
and then run `bin/setup` to get up and running. If you want to fool around in
a console with the changes you made, run `bin/console`.

Bug reports and pull requests are welcome on GitHub at
https://github.com/nedap/mysql-binuuid-rails

## Testing
For the most recent major version of ActiveRecord, tests are run against the
latest patch level of all minor versions. For earlier major versions, tests are
run against the latest minor/patch.

Run tests yourself to verify everything is still working:

```
$ bundle exec rake
```

## Contributors
See [CONTRIBUTORS.md](CONTRIBUTORS.md).


# License
The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
