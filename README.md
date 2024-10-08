# RuboCop::Angellist

A custom rubocop extension and default config for AL ruby projects.

## Usage

Add the gem to the development dependencies:

```ruby
group :development do
  gem 'rubocop-angellist', git: 'git@github.com:angellist/rubocop-angellist.git'
end
```

and then inherit the default config in the project's `.rubocop.yml`:

```yml
inherit_gem:
  rubocop-angellist: rubocop.yml

# ... rest of config
```

## Configuring Cops

1. Add your rule configuration to the `rubocop.yml` file in top level of this repo
2. Commit the changes through PR
3. Run `bundle update rubocop-angellist` in your project to pull the latest changes.

## Adding Custom Cops

Follow the directions [here](https://docs.rubocop.org/rubocop/development.html#create-a-new-cop).

New custom cops will be automatically included and configured with the defaults.
