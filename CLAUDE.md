# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

DynamicImage is a Rails engine for image uploads. It stores the original file and generates cropped, resized and format-converted versions on demand, rather than building a fixed set of derivatives at upload time. Storage is delegated to [dis](https://github.com/elektronaut/dis); processing is done with libvips via ruby-vips.

## Commands

```bash
bundle exec rspec                                   # Run all tests
bundle exec rspec spec/dynamic_image/model_spec.rb  # Run single test file
bundle exec rspec spec/dynamic_image/model_spec.rb:27 # Run test at specific line
bundle exec rubocop                                 # Lint
```

libvips must be installed for anything to run (`brew install vips`).

## Architecture

### Request flow

`image_resources` (`DynamicImage::Routing`) declares the routes: `show`, plus `uncropped`, `original` and `download` as member actions. The URL carries a digest, an optional size, and `to_param` (id plus an `updated_at` fingerprint).

`DynamicImage::Controller` runs `verify_signed_params` before anything else, then finds the record and checks `stale?`. `show` and `uncropped` go through `DynamicImage::ProcessedImage`; `original` and `download` stream the stored file via `send_dis_data` with no processing.

### Signing

Every URL is signed. `DynamicImage::DigestVerifier` generates an HMAC over `"{action}-{id}-{size}"` — note that the format is deliberately *not* part of the key, so one signature covers every format of the same image. The secret comes from `app.key_generator.generate_key("dynamic_image")` in the engine initializer, so it follows `secret_key_base`. A mismatch raises `Errors::InvalidSignature`, mapped to `401` via `rescue_responses`.

Helpers in `DynamicImage::Helper` generate the digest, which is why URLs can only be built server-side.

### Model

`DynamicImage::Model` includes `Dis::Model` and four concerns: `Dimensions` (vector accessors over the `crop_*`/`real_*` columns), `Transformations` (`resize`, `rotate`), `Validations` and `Variants`. A `before_validation` hook reads metadata off the file whenever the data changes, so `colorspace`, `real_width`, `real_height` and `content_type` always come from the file itself, never from the client.

`safe_content_type` negotiates against `DynamicImage.default_formats`: an uploaded format in that list is served as-is, anything else converts to the closest fit that keeps the image's animation and transparency. Views resolve `format:` the same way through `DynamicImage::Helper::Formats`, except mailer views, which fall back to `DynamicImage.mailer_formats`.

### Processing pipeline

`ImageReader` sniffs the header and hands off to vips. `ImageProcessor` wraps a `Vips::Image` and is immutable — every operation returns a new instance, so it chains: `.crop(...).resize(...).convert(...).read`. Its behavior is split across `ImageProcessor::Colors` (sRGB conversion, profile handling), `::Frames` (animated GIF/WebP) and `::Transform` (crop, resize, rotate).

`DynamicImage::Format` is a registry of the supported formats, holding magic bytes for sniffing, content types, extensions, save options and whether the format is animated. Formats are registered at the bottom of the class body.

Cropping always happens before resizing. `ImageSizing` computes both: `crop_geometry` returns the crop rect scaled to the source image, and `fit` computes the final dimensions honoring `:crop` and `:upscale`.

### Variants

Each processed size is persisted as a `DynamicImage::Variant` — a `Dis::Model` of its own under `dis_type` `"image-variants"`, with a unique index on image, format and the full crop geometry. `ProcessedImage#find_or_create_variant` rescues `RecordNotUnique` to handle concurrent requests for the same size, and `find_variant` self-heals by destroying records whose blob has gone missing from storage. Variants are destroyed on `before_update` when the image data changes.

## Test environment

Tests run against an internal Rails app at `spec/internal`, SQLite locally and PostgreSQL in CI (`DB=postgres`). Models: `Image` (includes `DynamicImage::Model`), `Photo` (the same, under a name that doesn't collide with the `image_path` asset helper), `LegacyImage` (a table predating `frame_count` and `alpha`), `User` (`belongs_to_image :avatar`), `Post`. Fixtures in `spec/support/fixtures` cover each supported format plus the awkward cases — CMYK, grayscale, Adobe RGB, EXIF-rotated, animated GIF and WebP.

## Rubocop

Max line length 80 (auto-corrected). Plugins: rubocop-rails, rubocop-rspec, rubocop-rspec_rails. Target Ruby 3.2, target Rails 7.2. `Style/Documentation` is disabled.
