# SequelCombine

This extension adds the `Sequel::Dataset#combine` method, which returns object from database composed with childrens, parents or any object where exists any relationship. Now it is possible in one query!

## Installation

Add this line to your application's Gemfile:

    gem 'sequel-combine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel-combine

## Usage

Remember! **Combined dataset** it's still a dataset so methods can be chained!

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
