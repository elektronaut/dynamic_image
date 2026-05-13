# Changelog

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
