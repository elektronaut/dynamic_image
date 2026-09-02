[![Version](https://img.shields.io/gem/v/dynamic_image.svg?style=flat)](https://rubygems.org/gems/dynamic_image)
[![Build](https://github.com/elektronaut/dynamic_image/actions/workflows/build.yml/badge.svg)](https://github.com/elektronaut/dynamic_image/actions/workflows/build.yml)

# DynamicImage

A Rails engine for image uploads.

Rather than creating a pre-defined set of images when a file is
uploaded, DynamicImage stores the original file and generates images
on demand. It handles cropping, resizing, format and colorspace
conversion.

DynamicImage is built on [Dis](https://github.com/elektronaut/dis)
and [ruby-vips](https://github.com/libvips/ruby-vips).

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

Run the `dis:install` generator to set up your storage. Files are stored
in `db/dis` by default; edit the generated initializer to change that.
See the [Dis](https://github.com/elektronaut/dis) documentation for the
options.

```sh
bin/rails generate dis:install
```

## Getting started

### Creating your resource

The `dynamic_image:resource` generator creates an `Image` model and a
controller, along with a migration and the necessary routes. The
migration creates the table for your resource, plus the table
DynamicImage uses to cache processed images.

```sh
bin/rails generate dynamic_image:resource image
bin/rails db:migrate
```

The generated route collides with any static images stored in
`public/images`. Customize the path in the route declaration if that's a
problem.

```ruby
image_resources :images, path: "dynamic_images/:digest(/:size)"
```

<details>
<summary>Setting the model up by hand</summary>

Include `DynamicImage::Model` and provide these columns. The first four
are required by Dis, the rest hold the image metadata and crop.

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

</details>

### Storing an image

To save an image, assign the uploaded file to the `file` attribute.

```ruby
Image.create(params.expect(image: [:file]))
```

The image is parsed and validated when the record is saved. Dimensions,
colorspace and content type are read from the file itself, so anything
the client claims about the upload is ignored. If the file isn't a
readable image in a supported format, the record is invalid and an error
is added to `data`.

### Associating images with other models

`belongs_to_image` works like `belongs_to` and takes the same options.
In addition to a record, it accepts an uploaded file directly and
creates the image record for you, so a file can be posted straight to
the parent model.

```ruby
class User < ActiveRecord::Base
  belongs_to_image :avatar, class_name: "Image"
  validates_associated :avatar
end
```

```erb
<%= form_with(model: user) do |f| %>
  <%= f.file_field :avatar %>
<% end %>
```

```ruby
User.create(params.expect(user: [:name, :avatar]))
```

`validates_associated` is optional, but without it an invalid upload is
silently dropped when the parent is saved. Like `belongs_to`, the
association is required by default; pass `optional: true` if the image
is allowed to be missing.

## Image URLs

`dynamic_image_path` and `dynamic_image_url` act pretty much like
regular URL helpers, and take the sizing options below.

```erb
<%= link_to "See image", dynamic_image_path(image, size: "400x400") %>
```

Every URL is signed and timestamped, so they can only be built
server-side. See [signed URLs](#signed-urls) for why.

### Sizing options

Every helper that renders or links to a processed image takes the same
sizing options.

* `:size` - Desired image size, as `"{width}x{height}"`. The image is
  scaled to fit within the size, preserving the aspect ratio. Omit
  either dimension (`"400x"` or `"x400"`) for a fixed width or height.
* `:crop` - Crop the image to the exact size instead of fitting it.
  Both dimensions are required.
* `:upscale` - By default, images are never scaled up, only down. Pass
  `upscale: true` to allow the image to be scaled beyond its own size.
* `:format` - Render the image in a different format. See
  [Formats](#formats).

### Other versions of the image

Three variations are available. `uncropped` has `_tag`, `_path` and
`_url` helpers; `original` and `download` have `_path` and `_url`.
`uncropped` takes the sizing options; `original` and `download` serve
the stored file untouched and ignore them.

* `original_dynamic_image_path` links to the file exactly as it was
  uploaded, with no processing at all.
* `download_dynamic_image_path` serves the original as an attachment,
  prompting a download.
* `uncropped_dynamic_image_tag` renders the image with any pre-cropping
  ignored.

```erb
<%= link_to "Download", download_dynamic_image_path(image) %>
```

## Displaying images

`dynamic_image_tag` renders an `img`, taking the sizing options above
plus any HTML attributes.

```erb
<%= dynamic_image_tag(image) %>
<%= dynamic_image_tag(image, size: "400x400") %>
<%= dynamic_image_tag(image, size: "400x400", crop: true) %>
```

### Alt text

The `alt` attribute is resolved from `DynamicImage::Model#alt_text`. The
column isn't added by default, either create it yourself, or override the
method. Alternatively, pass the `alt` option to the helper.

```erb
<%= dynamic_image_tag(image, alt: "A description") %>
<%= dynamic_image_tag(image, alt: "") %>
```

### Responsive images

`dynamic_picture_tag` renders a `picture` element covering a range of
widths using `srcset`.

```erb
<%= dynamic_picture_tag(image, sizes: "50vw", alt: "A description") %>
```

```html
<picture>
  <source type="image/webp"
          srcset="/images/… 420w, /images/… 590w, /images/… 830w, …"
          sizes="50vw">
  <img src="/images/…/1200x800/….jpg" width="1200" height="800"
       alt="A description">
</picture>
```

Note that there is no `size:` option here. Instead, pass a `ratio:`
when you want the image cropped. In addition to the `"16:9"` example
below, it also accepts rationals and floats.

```erb
<%= dynamic_picture_tag(image, ratio: "16:9", sizes: "50vw") %>
```

#### Image breakpoints

The `srcset` sizes are computed per image based on its own width,
stepping down geometrically in intervals, configured by `step:`.
The default configuration yields roughly 7 variants across the range,
depending on the original size.

```ruby
DynamicImage.default_breakpoints    = 320..3200
DynamicImage.breakpoint_step        = 1.4
DynamicImage.picture_fallback_width = 1200
```

If you'd rather have fixed widths, change the range to an array:

```ruby
DynamicImage.default_breakpoints = [400, 800, 1200]
```

All three options can be overridden per call.

```erb
<%= dynamic_picture_tag(image, sizes: "50vw",
                        breakpoints: 320..1600, step: 1.25) %>
<%= dynamic_picture_tag(image, sizes: "50vw", breakpoints: [400, 800, 1200]) %>
<%= dynamic_picture_tag(logo, sizes: "120px", breakpoints: 240) %>
```

#### Media queries

`dynamic_picture_source_tag` renders a single `source`, so you can
compose a `picture` by hand when you want different crops depending on
media queries.

```erb
<picture>
  <%= dynamic_picture_source_tag(image, ratio: "21:9",
                                 media: "(min-width: 1000px)") %>
  <%= dynamic_picture_source_tag(image, ratio: "1:1") %>
  <%= dynamic_image_tag(image, size: "1200x1200", crop: true, alt: "…") %>
</picture>
```

## Formats

Supported formats are JPEG, PNG, GIF, WebP, JPEG XL and TIFF.
HEIC and AVIF can also be uploaded, but aren't supported for output.

The preferred format lists are configurable, sorted most preferred format
first:

```ruby
DynamicImage.default_formats = %i[jpeg png gif webp]
DynamicImage.mailer_formats = %i[jpeg png gif]
```

Unless the source format matches the preferred formats, it will
be converted to the most appropriate format. For instance, a HEIC from
a phone will be served as either JPEG or PNG, depending on if it's
transparent or not.

Pass `format:` to override the defaults.

```erb
<%= dynamic_image_tag(image, size: "400x400", format: %i[jpeg png gif]) %>
<%= dynamic_image_tag(image, size: "400x400", format: :jxl) %>
```

For consistent appearance, all images are converted to the sRGB colorspace.
Any embedded color profiles will be taken into account when doing so.

## Working with images

### Cropping

Images can be pre-cropped by setting `crop_width`, `crop_height`,
`crop_start_x` and `crop_start_y`. The crop is applied to every rendered
version of the image, except the ones served by the `original` and
`uncropped` actions.

```ruby
image.update(
  crop_start_x: 15,
  crop_start_y: 20,
  crop_width: 300,
  crop_height: 200
)
image.size      # => Vector2d(300, 200)
image.real_size # => Vector2d(500, 400)
```

By default, images are cropped from the center. Set `crop_gravity_x` and
`crop_gravity_y` to set a different focal point. When cropping,
DynamicImage will attempt to keep this pixel as close to the center as
possible without zooming in.

The crop gravity is relative to the original image, so that the crop size
can change without moving the focal point.

```ruby
image.update(crop_gravity_x: 120, crop_gravity_y: 80)
```

### Transforming the stored image

Rendering never modifies the stored file, but `rotate` and `resize` do.
Both write a new file and update the stored dimensions, and neither
saves the record for you.

```ruby
image.rotate(90)
image.resize(Vector2d.new(800, 800))
image.save
```

`rotate` turns the image, taking the crop along with it. The angle must
be a multiple of 90.

`resize` scales the stored file down and replaces the original.

### Outside of views

The helpers cover rendering in HTML, but the classes underneath are
public API and useful when you need dimensions or image data directly.

#### Calculating sizes

`DynamicImage::ImageSizing` can be used for size calculation.
It takes the same options as the helpers.

```ruby
sizing = DynamicImage::ImageSizing.new(image) # a 1600x1000 image

sizing.fit("400x400")             # => Vector2d(400.0, 250.0)
sizing.fit("400x400", crop: true) # => Vector2d(400.0, 400.0)
sizing.fit("2000x2000")           # => Vector2d(1600.0, 1000.0)
```

#### Processing images

`DynamicImage::ProcessedImage` returns processed image data as a binary
string.

```ruby
size = DynamicImage::ImageSizing.new(image).fit("800x800")
data = DynamicImage::ProcessedImage.new(image, format: :jpg)
                                   .cropped_and_resized(size)
```

The result is stored as a variant, so that subsequent calls are cheap.

## How it works

### Signed URLs

All URLs are signed with a HMAC to protect against denial of service and
enumeration attacks.

The signing key is derived from your application's `secret_key_base`.
Take care if you rotate it, this will invalidate every image URL you
have generated. Plan for that if you rotate secrets.

### Caching

Generating images on the fly is expensive, so each processed size is
stored as a variant, a separate record with its data in Dis, and reused
on subsequent requests. Variants are discarded automatically when the
image is replaced.

Responses are served with a far-future `Cache-Control` header and
respect `If-Modified-Since`, so they play well with an HTTP cache in
front — [CloudFlare](https://www.cloudflare.com),
[Rack::Cache](http://rtomayko.github.io/rack-cache/) or
[actionpack-page_caching](https://github.com/rails/actionpack-page_caching),
to name a few. It's perfectly safe to cache images indefinitely: the URL
is timestamped, and will change if the object changes.

## Upgrading

DynamicImage can't migrate your image table for you: it's named whatever
you called it, and you may have several. When a release changes the
schema, you generate the migration. Most releases don't.

### 3.1

Uploaded WebP is now served as WebP instead of being converted to JPEG,
so URLs and cached variants for WebP images change. Mailer views still
get JPEG, PNG or GIF. Set `DynamicImage.default_formats` back to
`%i[jpeg png gif]` to keep the old behaviour.

This release also adds `frame_count` and `alpha`, and an index on
`content_hash`. Run this once per image model.

```sh
bin/rails generate dynamic_image:upgrade Image
bin/rails db:migrate
bin/rails dynamic_image:backfill MODELS=Image
```

The backfill reads every image back from storage, so it takes a while on
a large library. It's safe to interrupt and re-run, and it leaves
`updated_at` alone, so existing URLs and cached variants stay valid.

Two things to watch on a large table. `add_index` locks the table while
it builds, so move it into its own migration with
`algorithm: :concurrently`. And if your table was created by an older
generator, its columns are all nullable and the generator will list the
ones that should be `NOT NULL`; correcting them is optional and left to
you, since `change_column_null` fails if any row holds a `NULL`.

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
