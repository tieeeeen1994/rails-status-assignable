# Status Assignable

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'status_assignable', '~> 0.1'
```

## Usage

### Model

In your model, add the following line:

```ruby
class ModelName < ApplicationRecord
  include StatusAssignable
  # or
  has_assignable_status

  # ...
end
```

Then add a new migration that will add a status column to the model's database table:

```bash
rails g migration AddStatusToModelName
```

```ruby
class AddStatusToModelName < ActiveRecord::Migration[<RAILS VERSION>]
  def change
    add_column :model_names, :status, :integer, default: 1
    # 0 = deleted, 1 = active, 2 = inactive
  end
end
```

Your model is now status assignable!

```ruby
my_model = ModelName.find(1)
my_model.inactive! # Set the status to inactive
my_model.inactive? # true
my_model.deleted! # Set the status to deleted
my_model.deleted? # true
my_model.active! # Set the status to active
my_model.active? # true
my_model.soft_destroy # Archive the record with callbacks and its associations
my_model.archive # Alias of soft_destroy
my_model.soft_delete # Directly update the column in the database and also update its associations
```

#### Custom Status

You can also add your own status if need be. For example, if you want to add a `pending` status:

```ruby
class ModelName < ApplicationRecord
  include StatusAssignable[pending: 3]
  # or...
  has_assignable_status pending: 3

  # ...
end
```

This will add a `pending` status for your model. You can then use it like so:

```ruby
my_model = ModelName.find(1)
my_model.pending! # Set the status to pending
my_model.pending? # true
```

**Take note that the application will raise an exception if the default statuses are overridden. Use different key-value pair for your custom status if that happens.**

### Associations

Model associations are also supported. For example, if you have a `User` that has many `Post`s and `Comment`s, you can add the following line to the `User` model:

```ruby
class User < ApplicationRecord
  has_assignable_status

  has_many :posts, dependent: :destroy, archive: :callbacks
  has_many :comments, dependent: :delete_all, archive: :assign
  has_many :favorites, dependent: :destroy, archive: :destroy
end
```

The `archive` option can be set to `:callbacks`, `:assign` or `:destroy`. If set to `:callbacks`, the associated records will be archived using `soft_destroy`. If set to `:assign`, the associated records will have their status columns assigned directly. If set to `:destroy`, the associated records will be directly destroyed.

It is important that the associations also are `StatusAssignable`!

### Callbacks

Callbacks are only fired when `archive` or `soft_destroy` is called. `soft_delete` **never** fires callbacks (the association will use callbacks if it has the `archive: :callbacks` option).

There are callback hooks supported for `soft_destroy`: `before_soft_destroy`, `around_soft_destroy`, `after_soft_destroy`. They work like any model callbacks, so use them if need be when archiving a record.

```ruby
class Post < ApplicationRecord
  has_assignable_status

  before_destroy -> { versions.destroy_all }
  before_soft_destroy :update_and_unlink_versions
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tieeeeen1994/status_assignable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/status_assignable/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Status Assignable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/status_assignable/blob/master/CODE_OF_CONDUCT.md).
