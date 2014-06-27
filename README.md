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

## Rendering images in your views

You should use the provided helpers for displaying images, this will ensure
that the generated URLs are properly signed and timestamped.

To display the image at it's original size, use `dynamic_image_tag` without
any options.

```html
<%= dynamic_image_tag image %>
```

To resize it, specify a max size. This will scale the image down to fit, but
no cropping will occur.

```html
<%= dynamic_image_tag image, size: '400x400' %>
```

Setting `crop: true` will crop the image to the exact size.

```html
<%= dynamic_image_tag image, size: '400x400', crop: true %>
```

Omitting either dimension will render the image at an exact width or height.

```html
<%= dynamic_image_tag image, size: '400x' %>
```

`dynamic_image_path` and `dynamic_image_url` act pretty much like regular URL
helpers.

```html
<%= link_to "See image", dynamic_image_path(image) %>
```

## License

Copyright 2006-2014 Inge Jørgensen

DynamicImage is released under the
[MIT License](http://www.opensource.org/licenses/MIT).