# Changelog

## [3.1.1](https://github.com/elektronaut/dynamic_image/compare/dynamic_image/v3.1.0...dynamic_image/v3.1.1) (2026-09-02)


### Bug Fixes

* Guard mailer_view? outside of view contexts ([16f7664](https://github.com/elektronaut/dynamic_image/commit/16f7664df7f9ed5b9494f73ccff94d3ebbfc85c1))
* Guard mailer_view? outside of view contexts ([9c84871](https://github.com/elektronaut/dynamic_image/commit/9c84871a7ff13f93c3460b588fde058fd48dd757))

## [3.1.0](https://github.com/elektronaut/dynamic_image/compare/dynamic_image/v3.0.9...dynamic_image/v3.1.0) (2026-09-02)


### Features

* Accept a list of formats in the image helpers ([17f8695](https://github.com/elektronaut/dynamic_image/commit/17f8695a616fe4bc102e7e7075f9ae68f7c964af))
* Add dynamic_image:upgrade generator ([daed516](https://github.com/elektronaut/dynamic_image/commit/daed5168d3c72701ea45593583e4a8755e789e72))
* Add HEIC, AVIF and JPEG XL ([cb266ac](https://github.com/elektronaut/dynamic_image/commit/cb266acc2507ac36e91708af7d9477bb551f264f))
* Add HEIC, AVIF and JPEG XL ([4159445](https://github.com/elektronaut/dynamic_image/commit/415944578d61318a79f9f6a279010e79b4a46909))
* Add responsive images ([13d869a](https://github.com/elektronaut/dynamic_image/commit/13d869abc7753b10e7a85c770d032f47224017c4))
* Add responsive images ([642af38](https://github.com/elektronaut/dynamic_image/commit/642af38a822b963dd7989327cee87e9f8f1244a1))
* Backfill frame count and alpha for existing images ([91a5a0a](https://github.com/elektronaut/dynamic_image/commit/91a5a0a01bd43614e4099e5fb92b8ed1d3ef8905))
* Fall back to a safe format list in mailer views ([b7ac8ea](https://github.com/elektronaut/dynamic_image/commit/b7ac8ea38b4c617ba5b01a4bab36b9910b7d2daf))
* Record frame count and alpha channel on the image ([a439181](https://github.com/elektronaut/dynamic_image/commit/a43918199e419fc321e0dd03e6e1000ef2cacd35))
* Record whether a format carries an alpha channel ([b92b3c1](https://github.com/elektronaut/dynamic_image/commit/b92b3c154222e338b42dfb4af342dad2d760c78a))
* Render the resource migration from DynamicImage::Schema ([9c8903d](https://github.com/elektronaut/dynamic_image/commit/9c8903ddb8e0dca5fd0a216b6c6afa8e071a5c16))
* Resolve alt text from the model ([bbd7790](https://github.com/elektronaut/dynamic_image/commit/bbd779021230aeaec684f27bf7af03f6b1b50634))
* Resolve alt text from the model ([131a43b](https://github.com/elektronaut/dynamic_image/commit/131a43b2f64c86911b06193ffd04e56e15eaa92f))
* Serve uploaded WebP as WebP ([294dfa0](https://github.com/elektronaut/dynamic_image/commit/294dfa045ab3a00910506806b4693ffd16a1deee))
* Serve uploaded WebP as WebP ([625880a](https://github.com/elektronaut/dynamic_image/commit/625880ad57e1d9a6f775bf5e0060f76306b44864))


### Bug Fixes

* Advertise the stored format on original and download ([32e194d](https://github.com/elektronaut/dynamic_image/commit/32e194d167a04aa918517e300dd5cef5aac8a8b3))
* Always render a &lt;picture&gt; tag in dynamic_picture_tag ([2d1d0b7](https://github.com/elektronaut/dynamic_image/commit/2d1d0b7a466e1f0ac7124a2f589f7ebdde1ec0ac))
* Build absolute URLs in mailer views ([21ad523](https://github.com/elektronaut/dynamic_image/commit/21ad52338fd09f349b7abb20a4e2eb5a8aa8bdc9))
* Let BMP originals be downloaded ([ad4cb2e](https://github.com/elektronaut/dynamic_image/commit/ad4cb2e6cb32b23682aa691afd839493e50224c3))
* Load spec support files from the spec directory ([371da4a](https://github.com/elektronaut/dynamic_image/commit/371da4a649298bf4f774951be0e87de84bca0d07))
* Make Picture#format private ([d3aa1aa](https://github.com/elektronaut/dynamic_image/commit/d3aa1aa5b8cfaafaed4e660dcf9bfc58dafbefbf))
* Resource generator fails to load on Rails 8.1 ([c52b8c0](https://github.com/elektronaut/dynamic_image/commit/c52b8c0b9dbaafb99adbfa8d6949934842865916))
* Resource generator fails to load on Rails 8.1 ([94c2a34](https://github.com/elektronaut/dynamic_image/commit/94c2a34b44da910ae227fc672701f3cb4c992af7))
* Round crop attributes when resizing ([6c92cf1](https://github.com/elektronaut/dynamic_image/commit/6c92cf1d5dfa179b8027a0c33abe7c3c619a4688))
* Round crop attributes when resizing ([023206f](https://github.com/elektronaut/dynamic_image/commit/023206f25c741c55fca1439bf6c0b175fd7d3716))
* Wrap Vips::Error in Errors::InvalidImage when processing ([09399bd](https://github.com/elektronaut/dynamic_image/commit/09399bd97f418a0114894d75660696baf995b4e1))

## [3.0.9](https://github.com/elektronaut/dynamic_image/compare/dynamic_image/v3.0.8...dynamic_image/v3.0.9) (2026-08-29)


### Bug Fixes

* replace data_file_path with the dis 2.1 data access API ([390c715](https://github.com/elektronaut/dynamic_image/commit/390c715f5d37fb50938847a6b730d1b826355812))
* replace data_file_path with the dis 2.1 data access API ([ecf3e34](https://github.com/elektronaut/dynamic_image/commit/ecf3e347c5aac50b863fdf7c1c7b6a8344932f5a))

## [3.0.8](https://github.com/elektronaut/dynamic_image/compare/dynamic_image/v3.0.7...dynamic_image/v3.0.8) (2026-05-13)


### Bug Fixes

* install libvips in publish workflow job ([01fff8c](https://github.com/elektronaut/dynamic_image/commit/01fff8cc8943ed01f578a7b907f55743a00dbf6d))
* reject non-WEBP RIFF uploads and rescue Vips::Error in metadata ([#86](https://github.com/elektronaut/dynamic_image/issues/86)) ([6c2cf35](https://github.com/elektronaut/dynamic_image/commit/6c2cf35392cab5b06f0fc2197f2a36ef2adfb3c6))

## [3.0.7](https://github.com/elektronaut/dynamic_image/compare/dynamic_image-v3.0.6...dynamic_image/v3.0.7) (2026-02-21)


### Performance Improvements

* replace tempfile round-trip with write_to_buffer ([1c9befb](https://github.com/elektronaut/dynamic_image/commit/1c9befbf84eec31ee87347bdb7fd9fffb1450043))
* stream responses with send_file ([3d37fbb](https://github.com/elektronaut/dynamic_image/commit/3d37fbb820ea9269384c2be53c8ea72031dd7f43))
* use file paths instead of loading data into Ruby strings ([136f8c8](https://github.com/elektronaut/dynamic_image/commit/136f8c84dd767c5d91927f015dd1b48fe3b52b92))
* use header-only metadata extraction ([065a714](https://github.com/elektronaut/dynamic_image/commit/065a71431fa1feba1f039d0a2dbbfc0d2481e208))
