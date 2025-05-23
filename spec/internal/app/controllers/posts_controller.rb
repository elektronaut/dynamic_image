# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :find_post, only: %i[show edit update destroy]

  def index
    @posts = Post.order("created_at DESC")
  end

  def show; end

  def new
    @post = Post.new
  end

  def edit; end

  def create
    @post = Post.create(post_params)
  end

  def update
    @post.update(post_params)
  end

  delegate :destroy, to: :@post

  private

  def find_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:name, image_attributes: [:file])
  end
end
