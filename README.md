[![Version](https://img.shields.io/gem/v/dynamic_image.svg?style=flat)](https://rubygems.org/gems/dynamic_image)
![Build](https://github.com/elektronaut/dynamic_image/workflows/Build/badge.svg)
[![Code Climate](https://codeclimate.com/github/elektronaut/dynamic_image/badges/gpa.svg)](https://codeclimate.com/github/elektronaut/dynamic_image)
[![Code Climate](https://codeclimate.com/github/elektronaut/dynamic_image/badges/coverage.svg)](https://codeclimate.com/github/elektronaut/dynamic_image)

# DynamicImage

Need to handle image uploads in your Rails app?
Give DynamicImage a try.

Rather than creating a pre-defined set of images when a file is
uploaded, DynamicImage stores the original file and generates images
on demand. It handles cropping, resizing, format and colorspace
conversion.

Supported formats at the moment are JPEG, PNG, GIF, BMP, WebP and TIFF.
BMP, WebP and TIFF images will automatically be converted to JPG. CMYK
images will be converted to RGB, and RGB images will be converted to the sRGB
colorspace for consistent appearance in all browsers.

DynamicImage is built on [Dis](https://github.com/elektronaut/dis)
and [ruby-vips](https://github.com/libvips/ruby-vips).

All URLs are signed with a HMAC to protect against denial of service
and enumeration attacks.

## Requirements

* Rails 5+
* Ruby 2.7+
* libvips 8.8+

## Documentation

[Documentation is available on RubyDoc.info](http://rdoc.info/gems/dynamic_image)

## Installation

Add the gem to your Gemfile and run `bundle install`.

```ruby
gem "dynamic_image", "~> 3.0"
```

Run the `dis:install` generator to set up your storage.

```sh
bin/rails generate dis:install
```

You can edit the generated initializer to configure your storage, by default it
will store files in `db/dis`. See the
[Dis](https://github.com/elektronaut/dis) documentation for more
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

## Storing an image

To save an image, simply assign the file attribute to your uploaded file.

```ruby
image_params = params.require(:image).permit(:file)
Image.create(image_params)
```

## Rendering images in your views

You should use the provided helpers for displaying images, this will ensure
that the generated URLs are properly signed and timestamped.

To display the image at it's original size, use `dynamic_image_tag` without
any options.

```erb
<%= dynamic_image_tag(image) %>
```

To resize it, specify a max size. This will scale the image down to fit, but
no cropping will occur.

```erb
<%= dynamic_image_tag(image, size: "400x400") %>
```

Setting `crop: true` will crop the image to the exact size.

```erb
<%= dynamic_image_tag(image, size: "400x400", crop: true) %>
```

Omitting either dimension will render the image at an exact width or height.

```erb
<%= dynamic_image_tag(image, size: "400x") %>
```

`dynamic_image_path` and `dynamic_image_url` act pretty much like regular URL
helpers.

```erb
<%= link_to "See image", dynamic_image_path(image) %>
```

## Caching

Generating images on the fly is expensive. This is less of a problem
in development mode, as DynamicImage respects the If-Modified-Since
header. In production, you should absolutely cache the results.

DynamicImage doesn't do any caching on it's own, but it is designed to
play well with others. Here's a few options:

* [CloudFlare](https://www.cloudflare.com)
* [Rack::Cache](http://rtomayko.github.io/rack-cache/)
* [actionpack-page_caching](https://github.com/rails/actionpack-page_caching)

It's perfectly safe to cache images indefinitely. The URL is
timestamped, and will change if the object changes.

## License

Copyright 2006-2016 Inge Jørgensen

DynamicImage is released under the
[MIT License](http://www.opensource.org/licenses/MIT).
