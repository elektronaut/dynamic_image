# DynamicImage [![Build Status](https://travis-ci.org/elektronaut/dynamic_image.png)](https://travis-ci.org/elektronaut/dynamic_image) [![Code Climate](https://codeclimate.com/github/elektronaut/dynamic_image.png)](https://codeclimate.com/github/elektronaut/dynamic_image) [![Code Climate](https://codeclimate.com/github/elektronaut/dynamic_image/coverage.png)](https://codeclimate.com/github/elektronaut/dynamic_image)

Requires Rails 4.1+ and Ruby 1.9.3+.

## Installation

Add the gem to your Gemfile and run `bundle install`.

```ruby
gem "dynamic_image"
```

Run the `shrouded:install` generator to set up your storage.

```sh
bin/rails generate shrouded:install
```

You can edit the generated initializer to configure your storage, by default it
will store files in `db/shrouded`. See the
[Shrouded](https://github.com/elektronaut/shrouded) documentation for more
information.

## Creating your resource

Run the `dynamic_image:resource` generator to create your resource.

```sh
bin/rails generate dynamic_image:resource image
```

This will create an `Image` model and a controller, along with a migration and
the necessary routes.

Note that in this case, the route with collide with any static images stored
in `public/images`. You can customize the path if you want in the route
declaration.

```ruby
image_resources :images, path: "dynamic_images/:digest(/:size)"
```

## License

Copyright 2006-2014 Inge Jørgensen

DynamicImage is released under the [MIT License](http://www.opensource.org/licenses/MIT).