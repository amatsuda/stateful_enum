# StatefulEnum [![Build Status](https://travis-ci.org/amatsuda/stateful_enum.svg?branch=master)](https://travis-ci.org/amatsuda/stateful_enum)

stateful_enum is a state machine gem built on top of ActiveRecord's built-in ActiveRecord::Enum.


## Installation

Add this line to your Rails app's Gemfile:

```ruby
gem 'stateful_enum'
```

And bundle.


## Motivation

### You Ain't Gonna Need Abstraction

stateful_enum depends on ActiveRecord. If you prefer a "well-abstracted" state machine library that supports multiple datastores, or Plain Old Ruby Objects (who needs that feature?), I'm sorry but this gem is not for you.

### I Hate Saving States in a VARCHAR Column

From a database design point of view, I prefer to save state data in an INTEGER column rather than saving the state name directly in a VARCHAR column.

### :heart: ActiveRecord::Enum

ActiveRecord 4.1+ has a very simple and useful built-in Enum DSL that provides human-friendly API over integer values in DB.

### Method Names Should be Verbs

AR::Enum automatically defines Ruby methods per each label. However, Enum labels are in most cases adjectives or past participle, which often creates weird method names.
What we really want to define as methods are the transition events between states, and not the states themselves.


## Usage

The stateful_enum gem extends AR::Enum definition to take a block with a similar DSL to the [state_machine](https://github.com/pluginaweek/state_machine) gem.

Example:
```ruby
class Bug < ApplicationRecord
  enum status: {unassigned: 0, assigned: 1, resolved: 2, closed: 3} do
    event :assign do
      transition :unassigned => :assigned
    end

    event :resolve do
      before do
        self.resolved_at = Time.zone.now
      end

      transition [:unassigned, :assigned] => :resolved
    end

    event :close do
      after do
        Notifier.notify "Bug##{id} has been closed."
      end

      transition all - [:closed] => :closed
    end
  end
end
```

### Defining the States

Just call the AR::Enum's `enum` method.  The only difference from the original `enum` method is that our `enum` call takes a block.
Please see the full API documentation of [AR::Enum](http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) for more information.

### Defining the Events

You can declare events through `event` method inside of an `enum` block. Then stateful_enum defines the following methods per each event:

**An instance method to fire the event**

```ruby
@bug.assign  # does nothing and returns false if a valid transition for the current state is not defined
```

**An instance method with `!` to fire the event**
```ruby
@bug.assign!  # raises if a valid transition for the current state is not defined
```

**A predicate method that returns if the event is fireable**
```ruby
@bug.can_assign?  # returns if the `assign` event can be called on this bug or not
```

**An instance method that returns the state name after an event**
```ruby
@bug.assign_transition  #=> :assigned
```

### Defining the Transitions

You can define state transitions through `transition` method inside of an `event` block.

There are a few important details to note regarding this feature:

* The `transition` method takes a Hash each key of which is state "from" transitions to the Hash value.
* The "from" states and the "to" states should both be given in Symbols.
* The "from" state can be multiple states, in which case the key can be given as an Array of states, as shown in the usage example.
* The "from" state can be `all` that means all defined states.

### :if and :unless Condition

The `transition` method takes an `:if` or/and `:unless` option as a Proc.
Mutually exclusive `:if` and `:unless` conditions though will raise an error.

Example:
```ruby
event :assign do
  transition :unassigned => :assigned, if: -> { !!assigned_to }
end
```

### Event Hooks

You can define `before` and `after` event hooks inside of an `event` block.


## Generating State Machine Diagrams

stateful_enum includes a Rails generator that generates a state machine diagram.
Note that you need to bundle the ruby-graphviz gem (and its dependencies) for the development env in order to run the generator.

```bash
% rails g stateful_enum:graph bug
```

You can specify relative or absolute output path via environment variable `DEST_DIR`.

```bash
% DEST_DIR=doc rails g stateful_enum:graph bug
```

## TODO

* Better Error handling


## Support Rails Versions

* Rails 4.1.x, 4.2.x, 5.0, 5.1, and 5.2 (edge)


## Contributing

Pull requests are welcome on GitHub at https://github.com/amatsuda/stateful_enum.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
