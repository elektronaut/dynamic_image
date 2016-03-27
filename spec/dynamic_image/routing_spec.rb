require 'spec_helper'

describe ImagesController, type: :routing do
  let(:file_path) { '../../support/fixtures/image.png' }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { 'image/png' }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.create(file: uploaded_file) }

  describe 'show' do
    it 'routes the URL' do
      expect(get('/images/123456/100x100/1-20140606.png')).to(
        route_to(
          controller: 'images',
          action: 'show',
          id: '1-20140606',
          digest: '123456',
          size: '100x100',
          format: 'png'
        )
      )
    end

    it 'routes the named route' do
      expect(
        get: image_path('123456', '100x100', id: '1-20140606', format: 'png')
      ).to(
        route_to(
          controller: 'images',
          action: 'show',
          id: '1-20140606',
          digest: '123456',
          size: '100x100',
          format: 'png'
        )
      )
    end

    it 'does not route URLs with an invalid size' do
      expect(get('/images/123456/100x/1-20140606.png')).not_to be_routable
    end
  end

  describe 'uncropped' do
    it 'routes the URL' do
      expect(get('/images/123456/100x100/1-20140606/uncropped.png')).to(
        route_to(
          controller: 'images',
          action: 'uncropped',
          id: '1-20140606',
          digest: '123456',
          size: '100x100',
          format: 'png'
        )
      )
    end

    it 'routes the named route' do
      expect(
        get: uncropped_image_path(
          '123456',
          '100x100',
          id: '1-20140606',
          format: 'png'
        )
      ).to(
        route_to(
          controller: 'images',
          action: 'uncropped',
          id: '1-20140606',
          digest: '123456',
          size: '100x100',
          format: 'png'
        )
      )
    end
  end

  describe 'original' do
    it 'routes the URL' do
      expect(get('/images/123456/1-20140606/original.png')).to(
        route_to(
          controller: 'images',
          action: 'original',
          id: '1-20140606',
          digest: '123456',
          format: 'png'
        )
      )
    end

    it 'routes the named route' do
      expect(
        get: original_image_path('123456', id: '1-20140606', format: 'png')
      ).to(
        route_to(
          controller: 'images',
          action: 'original',
          id: '1-20140606',
          digest: '123456',
          format: 'png'
        )
      )
    end
  end
end
