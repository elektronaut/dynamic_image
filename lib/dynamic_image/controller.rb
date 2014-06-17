# encoding: utf-8

module DynamicImage
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :find_record, only: [:show]
      respond_to :html
    end

    def show
      respond_with(@record) do |format|
        format.html { render text: "OK" }
      end
    end

    private

    def find_record
      @record = model.find(params[:id])
    end
  end
end