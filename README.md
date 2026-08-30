[![Version](https://img.shields.io/gem/v/dynamic_image.svg?style=flat)](https://rubygems.org/gems/dynamic_image)
[![Build](https://github.com/elektronaut/dynamic_image/actions/workflows/build.yml/badge.svg)](https://github.com/elektronaut/dynamic_image/actions/workflows/build.yml)

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

## Installation

DynamicImage requires [libvips](https://www.libvips.org), which is
available from most package managers.

```sh
brew install vips
```

Add the gem to your Gemfile and run `bundle install`.

```ruby
gem "dynamic_image", "~> 3.0"
```

Run the `dis:install` generator to set up your storage.

```sh
bin/rails generate dis:install
```

You can edit the generated initializer to configure your storage. By
default it will store files in `db/dis`. See the
[Dis](https://github.com/elektronaut/dis) documentation for more
information.

## Creating your resource

Run the `dynamic_image:resource` generator to create your resource.

```sh
bin/rails generate dynamic_image:resource image
```

This will create an `Image` model and a controller, along with a migration and
the necessary routes.

Note that in this case, the route will collide with any static images
stored in `public/images`. You can customize the path if you want in the
route declaration.

```ruby
image_resources :images, path: "dynamic_images/:digest(/:size)"
```

Run the migrations when you're done. This creates the table for your
resource, along with the table DynamicImage uses to cache processed
images.

```sh
bin/rails db:migrate
```

If you'd rather set the model up by hand, include `DynamicImage::Model`
and provide these columns. The four first are required by Dis, the rest
hold the image metadata and crop.

```ruby
create_table :images do |t|
  t.string  :content_hash, null: false
  t.string  :content_type, null: false
  t.integer :content_length, null: false
  t.string  :filename, null: false
  t.string  :colorspace, null: false
  t.integer :real_width, null: false
  t.integer :real_height, null: false
  t.integer :frame_count
  t.boolean :alpha
  t.integer :crop_width, :crop_height
  t.integer :crop_start_x, :crop_start_y
  t.integer :crop_gravity_x, :crop_gravity_y
  t.timestamps
end

add_index :images, :content_hash
```

The controller needs `DynamicImage::Controller` and a `model` method
telling it which class to serve.

```ruby
class ImagesController < ApplicationController
  include DynamicImage::Controller

  private

  def model
    Image
  end
end
```

## Storing an image

To save an image, simply assign the file attribute to your uploaded
file.

```ruby
Image.create(params.expect(image: [:file]))
```

The image is parsed and validated when the record is saved. Dimensions,
colorspace and content type are read from the file itself, so anything
the client claims about the upload is ignored. If the file isn't a
readable image in a supported format, the record is invalid and an error
is added to `data`.

## Associating images with other models

Other models can refer to images with `belongs_to_image`. It works like
`belongs_to`, and takes the same options.

```ruby
class User < ActiveRecord::Base
  belongs_to_image :avatar, class_name: "Image"
end
```

In addition to a record, the association accepts an uploaded file
directly, creating the image record for you. This means you can post a
file straight to the parent model.

```ruby
User.create(params.expect(user: [:name, :avatar]))
```

```erb
<%= form_with(model: user) do |f| %>
  <%= f.file_field :avatar %>
<% end %>
```

Add `validates_associated` if you want an invalid upload to invalidate the
parent record. Otherwise the assignment is silently dropped when the
parent is saved.

```ruby
class User < ActiveRecord::Base
  belongs_to_image :avatar, class_name: "Image"
  validates_associated :avatar
end
```

Like `belongs_to`, the association is required by default. Pass
`optional: true` if the image is allowed to be missing.

## Rendering images in your views

You should use the provided helpers for displaying images, this will ensure
that the generated URLs are properly signed and timestamped.

To display the image at its original size, use `dynamic_image_tag` without
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

Note that no `alt` attribute is generated for you. Pass one, as you would
to `image_tag`. Any other options that aren't listed below are passed
along as HTML attributes.

### Sizing options

`dynamic_image_tag`, `dynamic_image_path` and `dynamic_image_url` all
take the same sizing options.

* `:size` - Desired image size, as `"{width}x{height}"`. The image is
  scaled to fit within the size, preserving the aspect ratio. Omit
  either dimension (`"400x"` or `"x400"`) for a fixed width or height.
* `:crop` - Crop the image to the exact size instead of fitting it.
  Both dimensions are required; `size: "400x", crop: true` will raise
  `DynamicImage::Errors::InvalidSizeOptions`.
* `:upscale` - Images are only ever scaled down, never up. Pass
  `upscale: true` to allow the image to be scaled beyond its own size.
* `:format` - Render the image in a different format. See below.

### Formats

Images are served in the format they were uploaded in, as long as it's
one that renders everywhere: PNG, GIF and JPEG. Anything else, including
WebP and TIFF, is converted to the closest fit — animation is kept
before transparency, and a photograph becomes JPEG.

Both lists are configurable, most preferred format first:

```ruby
DynamicImage.default_formats = %i[jpeg png gif]
DynamicImage.mailer_formats = %i[jpeg png gif]
```

Mailer views use `mailer_formats`. Classic Outlook renders through the
Word engine, which has no WebP support. Mail composed with
`ApplicationController.render` can't be told apart from a browser
render, so pass `format:` yourself there.

Mailer views only get `_url` helpers, so pass `routing_type: :url`:

```erb
<%= dynamic_image_tag(image, size: "400x400", routing_type: :url) %>
```

Pass `format:` to pick the format for a single tag.

```erb
<%= dynamic_image_tag(image, size: "400x400", format: :webp) %>
```

Pass an array when several formats will do. The uploaded format is used
if it's in the list; otherwise the closest fit wins.

```erb
<%= dynamic_image_tag(image, size: "400x400", format: %i[jpeg png gif]) %>
```

Images stored before `frame_count` and `alpha` were recorded convert to
JPEG unless the uploaded format is in the list. See
[Upgrading](#upgrading).

The format is not part of the signature, so the same image can be served
in several formats without any extra bookkeeping.

Animated GIF and WebP images stay animated when converted between those
two formats. Converting an animated image to a still format renders the
first frame.

### Responsive images

Since any size can be generated on demand, `srcset` is just a matter of
listing the widths you want. `dynamic_image_tag` passes `srcset` and
`sizes` through to the underlying `img` tag.

```erb
<%= dynamic_image_tag(
      image,
      size: "800x",
      srcset: [400, 800, 1200].map { |w|
        "#{dynamic_image_path(image, size: "#{w}x")} #{w}w"
      }.join(", "),
      sizes: "(max-width: 600px) 100vw, 600px",
      alt: "A description of the image"
    ) %>
```

Combine it with `format:` to offer WebP to the browsers that want it.

```erb
<picture>
  <source srcset="<%= dynamic_image_path(image, size: "800x", format: :webp) %>"
          type="image/webp">
  <%= dynamic_image_tag(image, size: "800x", alt: "A description") %>
</picture>
```

Remember that each distinct size is processed and stored the first time
it is requested, so a handful of widths reused across the site will
serve you better than a different set on every template.

### Other versions of the image

Three variations are available, each with `_tag`, `_path` and `_url`
helpers. None of them take sizing options.

* `original_dynamic_image_tag` renders the file exactly as it was
  uploaded, with no processing at all.
* `download_dynamic_image_path` serves the original as an attachment,
  prompting a download.
* `uncropped_dynamic_image_tag` renders the image with any pre-cropping
  ignored.

```erb
<%= link_to "Download", download_dynamic_image_path(image) %>
```

## Cropping

Images can be pre-cropped by setting `crop_width`, `crop_height`,
`crop_start_x` and `crop_start_y`. The crop is applied to every rendered
version of the image, except the ones served by the `original` and
`uncropped` actions.

```ruby
image.update(
  crop_start_x: 15, crop_start_y: 20,
  crop_width: 300, crop_height: 200
)
image.size      # => Vector2d(300, 200)
image.real_size # => Vector2d(500, 400)
```

By default, images are cropped from the center. Set `crop_gravity_x` and
`crop_gravity_y` to move that focal point. DynamicImage will keep the
pixel at those coordinates within the cropped image, and as close to the
center as it can get without zooming in. The coordinates are relative to
the original image, not the pre-cropped one.

```ruby
image.update(crop_gravity_x: 120, crop_gravity_y: 80)
```

Gravity applies to any crop, not just the pre-crop: an image with no
`crop_width`/`crop_height` still uses it when a view asks for
`crop: true`.

## Transforming the stored image

Rendering never modifies the stored file, but two methods do. Both write
a new file and update the stored dimensions, and neither saves the record
for you.

`rotate` turns the image, taking the crop along with it. The angle must
be a multiple of 90; anything else raises
`DynamicImage::Errors::InvalidTransformation`.

```ruby
image.rotate(90)
image.save
```

`resize` scales the stored file down and replaces the original.

```ruby
image.resize(Vector2d.new(800, 800))
image.save
```

## Working with images outside of views

The helpers cover rendering in HTML, but the classes underneath are
public API and useful when you need dimensions or image data directly.

### Calculating sizes

`DynamicImage::ImageSizing` answers the question "what size would this
image be", without rendering anything. It takes the same options as the
helpers.

```ruby
sizing = DynamicImage::ImageSizing.new(image) # a 1600x1000 image

sizing.fit("400x400")             # => Vector2d(400.0, 250.0)
sizing.fit("400x400", crop: true) # => Vector2d(400.0, 400.0)
sizing.fit("2000x2000")           # => Vector2d(1600.0, 1000.0)
```

This is what you want for `og:image:width`, for JSON payloads that tell
a JavaScript component how much space to reserve, or for laying out a
PDF.

### Processing images

`DynamicImage::ProcessedImage` returns processed image data as a binary
string. Use it when the consumer can't fetch a URL — PDF generation is
the usual case.

```ruby
size = DynamicImage::ImageSizing.new(image).fit("800x800")
data = DynamicImage::ProcessedImage.new(image, format: :jpg)
                                   .cropped_and_resized(size)
```

Processing happens inline, so this is slow the first time and cheap
afterwards; the result is stored as a variant like any other size.

## Signed URLs

Every URL carries a HMAC digest of the action, the record id and the
size. Requests that don't match are rejected with
`DynamicImage::Errors::InvalidSignature`, which Rails renders as
`401 Unauthorized`.

Generating images is expensive, so an unsigned endpoint would be trivial
to exhaust; only sizes you have linked to can be requested. It also stops
ids being walked to find images you haven't linked to.

The signing key is derived from your application's `secret_key_base`.
Rotating it invalidates every image URL you have ever generated,
including ones sitting in a CDN or in the body of an already-sent email.
Plan for that if you rotate secrets.

## Caching

Generating images on the fly is expensive, so each processed size is
stored as a variant, a separate record with its data in Dis, and reused
on subsequent requests. Variants are discarded automatically when the
image is replaced.

Responses are served with a far-future `Cache-Control` header and
respect `If-Modified-Since`, so they play well with an HTTP cache in
front. Here are a few options:

* [CloudFlare](https://www.cloudflare.com)
* [Rack::Cache](http://rtomayko.github.io/rack-cache/)
* [actionpack-page_caching](https://github.com/rails/actionpack-page_caching)

It's perfectly safe to cache images indefinitely. The URL is
timestamped, and will change if the object changes.

## Upgrading

DynamicImage can't migrate your image table for you: it's named whatever
you called it, and you may have several. When a release changes the
schema, you generate the migration. Most releases don't.

### 3.1

Adds `frame_count` and `alpha`, and an index on `content_hash`. Run this
once per image model.

```sh
bin/rails generate dynamic_image:upgrade Image
bin/rails db:migrate
bin/rails dynamic_image:backfill MODELS=Image
```

The backfill reads every image back from storage, so it takes a while on
a large library. It's safe to interrupt and re-run, and it leaves
`updated_at` alone, so existing URLs and cached variants stay valid.

`add_index` locks the table while it builds. On a large table, move it
into its own migration with `algorithm: :concurrently`.

If your table was created by an older generator, its columns are all
nullable and the generator will list the ones that should be `NOT NULL`.
Correcting them is optional and left to you, since `change_column_null`
fails if any row holds a `NULL`.

## Documentation

See the [generated documentation on RubyDoc.info](https://www.rubydoc.info/gems/dynamic_image),
and the [changelog](CHANGELOG.md) for release notes.

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/elektronaut/dynamic_image). See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to run the tests and how
commits are formatted, and note that this project ships with a
[code of conduct](CODE_OF_CONDUCT.md).

## License

Released under the [MIT License](MIT-LICENSE).
