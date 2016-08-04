require 'spec_helper'

describe DynamicImage::Model::Transformations do
  let(:file_path) { '../../../support/fixtures/image.png' }
  let(:file) { File.open(File.expand_path(file_path, __FILE__)) }
  let(:content_type) { 'image/png' }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file, content_type) }

  let(:image) { Image.new(file: uploaded_file) }

  describe '#rotate' do
    let(:degrees) { 90 }
    let(:image) do
      Image.new(file: uploaded_file,
                crop_width: 40,
                crop_height: 30,
                crop_start_x: 20,
                crop_start_y: 10,
                crop_gravity_x: 50,
                crop_gravity_y: 60)
    end

    subject do
      image.rotate(degrees)
    end

    it { is_expected.to eq(image) }

    context 'invalid angle' do
      let(:degrees) { 45 }
      it 'should raise an error' do
        expect { subject }.to(
          raise_error(DynamicImage::Errors::InvalidTransformation)
        )
      end
    end

    context '90 degrees' do
      it 'should rotate the image' do
        expect(subject.real_size).to eq(Vector2d.new(200, 320))
      end

      it 'should adjust the crop size' do
        expect(subject.crop_size).to eq(Vector2d.new(30, 40))
      end

      it 'should adjust the crop start' do
        expect(subject.crop_start).to eq(Vector2d.new(160, 20))
      end

      it 'should adjust the crop gravity' do
        expect(subject.crop_gravity).to eq(Vector2d.new(140, 50))
      end
    end

    context '180 degrees' do
      let(:degrees) { 180 }

      it 'should keep the image size' do
        expect(subject.real_size).to eq(Vector2d.new(320, 200))
      end

      it 'should keep the crop size' do
        expect(subject.crop_size).to eq(Vector2d.new(40, 30))
      end

      it 'should adjust the crop start' do
        expect(subject.crop_start).to eq(Vector2d.new(260, 160))
      end

      it 'should adjust the crop gravity' do
        expect(subject.crop_gravity).to eq(Vector2d.new(270, 140))
      end
    end

    context '-90 degrees' do
      let(:degrees) { -90 }

      it 'should rotate the image' do
        expect(subject.real_size).to eq(Vector2d.new(200, 320))
      end

      it 'should adjust the crop size' do
        expect(subject.crop_size).to eq(Vector2d.new(30, 40))
      end

      it 'should adjust the crop start' do
        expect(subject.crop_start).to eq(Vector2d.new(10, 260))
      end

      it 'should adjust the crop gravity' do
        expect(subject.crop_gravity).to eq(Vector2d.new(60, 270))
      end
    end
  end
end
