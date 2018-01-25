# Overrider
[![Build Status](https://travis-ci.org/joker1007/overrider.svg?branch=master)](https://travis-ci.org/joker1007/overrider)

This gem adds `override` syntax that is similar to Java's one.
`override` syntax ensures that a modified method has super method.

Unless the method has super method, this gem raise `Overrider::NoSuperMethodError`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'overrider'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install overrider

## Usage

```ruby
class A1
  def foo
  end
end

class A2 < A1
  extend Overrider

  override def foo
  end
end
```

this is OK.

```ruby
class B1
end

class B2 < B1
  extend Overrider

  override def foo
  end
end # => raise
```

## Caution

Must not call `override` outer class definition.

ex.

```ruby
class A1
  def foo
  end
end

class A2 < A1
  extend Overrider

  def foo
  end
end

A2.send(:override, :foo)
```

This case leaves enabled TracePoint.
It is very high overhead.

### Examples

#### include module method after override method

```ruby
module C1
  def foo
  end
end

class C2
  extend Overrider

  override def foo
  end

  include C1
end # => OK
```

#### singleton method

```ruby
class D1
end

class D2 < D1
  extend Overrider

  class << self
    def foo
    end
  end

  override_singleton_method :foo
end # => raise
```

```ruby
class D2_1
  def self.foo
  end
end

class D2_2 < D2_1
  extend Overrider

  class << self
    def foo
    end
  end

  override_singleton_method :foo
end # => OK
```

#### extend singleton method after override method

```ruby
module E1
  def foo
  end

  def bar
  end
end

class E2
  extend Overrider

  class << self
    def foo
    end

    def bar
    end
  end

  override_singleton_method :foo
  override_singleton_method :bar

  extend E1
end # => OK
```

#### `Class.new` style

```ruby
class A1
  def foo
  end
end

Class.new(A1) do
  extend Overrider

  override def foo
  end
end # => OK
```

## How is it implemented?

Use `TracePoint` and `caller_locations` (to detect `class-end` or `Class.new { }`).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/overrider.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
