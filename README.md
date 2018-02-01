# SequelCombine
[![CircleCI](https://circleci.com/gh/monterail/sequel-combine/tree/master.svg?style=shield)](https://circleci.com/gh/monterail/sequel-combine/tree/master) [![Gem Version](https://badge.fury.io/rb/sequel-combine.svg)](https://badge.fury.io/rb/sequel-combine) [![Code Climate](https://codeclimate.com/github/monterail/sequel-combine/badges/gpa.svg)](https://codeclimate.com/github/monterail/sequel-combine)

This extension adds the `Sequel::Dataset#combine` method, which returns object from database composed with childrens, parents or any object where exists any relationship. Now it is possible in one query!

## Installation

Add this line to your application's Gemfile:

    gem 'sequel-combine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel-combine

The plugin needs to be initialized by the Sequel extension interface. The simplest way to configure plugin globally is adding this line to the initializer:

```ruby
Sequel.extension :combine
```
or
```ruby
Sequel::Database.extension :combine
```

But anyway I recommend reading more about [Sequel extensions system](https://github.com/jeremyevans/sequel/blob/master/doc/extensions.rdoc#sequel-extensions).

## Usage

Remember!
**Combined dataset** it's still a dataset so methods can be chained!

Combining works only with **Postgres** adapter

```ruby
dataset_first
  .combine(many: { attribute: [dataset_second, p_key_dataset_second: :f_key_dataset_first] })
  .to_a
```
* `dataset_first`, `dataset_second` -> datasets which needs to be combined
* `many` -> method used in combining. If relation is one-to-one recommended method is `one`(which return object or nil), in any other case I recommend to using method `many`(which return array of objects or empty array). 
* `attribute` -> attribute which will be an result of combine
* `p_key_dataset_second: :f_key_dataset_first` -> relationship between tables

## Usage examples

### Combining many
```ruby
DB[:groups].columns
  #=> [:id, :name]
DB[:users].columns
  #=> [:id, :username, :email, :group_id]
DB[:groups].combine(many: { users: [DB[:users], id: :group_id] }).to_a
  #=> [{:id=>1,
  #     :name=>"Football",
  #     :users=>
  #       [{
  #           :id=> 1,
  #           :username=> "leonardo",
  #           :email=> "leonardo@fakemail.com",
  #           :group_id=> 1,
  #         },
  #         {
  #           :id=> 2,
  #           :username=> "leonardo2",
  #           :email=> "leonardo2@fakemail.com",
  #           :group_id=> 1,
  #         },
  #       ]
  #   }]
```

### Combining one
```ruby
DB[:groups].columns
  #=> [:id, :name]
DB[:users].columns
  #=> [:id, :username, :email, :group_id]
DB[:users].combine(one: { group: [DB[:groups], group_id: :id] }).to_a
  #=> [
  #     {
  #       :id=> 1,
  #       :username=> "leonardo",
  #       :email=>  "leonardo@fakemail.com",
  #       :group=> { :id=> 1, :name=> "Football" },
  #     },
  #     {
  #       :id=> 2,
  #       :username=> "leonardo2",
  #       :email=> "leonardo2@fakemail.com"
  #       :group=> { :id=> 1, :name=> "Football" },
  #     }
  #   ]
```

### Combining one and many
Also combining can be mixed and multiplied:
```ruby
DB[:users].combine(
    one: {
      group: [DB[:groups], group_id: :id],
      company: [DB[:companies], company_id: :id],
    },
    many: {
      tasks: [DB[:tasks], id: :user_id],
      roles: [DB[:roles], id: :user_id],
    },
  ).to_a
```

### Combining inside combine
It can go deeper and deeper...
```ruby
DB[:projects].combine(
  many: {
    users: [
      DB[:users].combine(one: { city: [DB[:cities], city_id: :id] }),
      id: :project_id,
    ]
  }
).to_a
```

### Self-combining and combining not by foreign_key
```ruby
DB[:geolocations].combine(one: { parent: [DB[:geolocations], path: :parent_path] }).to_a
```

### Combining more complex datasets
Datasets used in combine might be of course chained with other `Sequel::Dataset` methods.
```ruby
DB[:groups]
    .where(id: 1)
    .select(:id, :name)
    .order(:name)
    .combine(
        many: { 
            users: [
                DB[:users]
                    .join(:groups)
                    .select(:id, :username, :group_id, Sequel.qualify("groups", "name")), 
                id: :group_id
            ] 
        }
    ).to_a
```

## Benchmark
Tested on 2000 mocked records with children's or parents:

4 level of combine - 2,39 sec.

3 level - 1,12 sec.

2 level - 0,55 sec.

1 level - 0,22 sec.

self-combining (the situation from geolocation, tested on real geolocations database, around 23000 records) - 4 sec

## Use cases

* API directly in Postgresql
* Exporting tree of objects
* **deep clone** in Postgresql - very extreme case, but it's probably the most performance effective way of doing this operation
* more, more, more...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
