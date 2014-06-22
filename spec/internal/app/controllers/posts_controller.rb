class PostsController < ApplicationController
  before_action :find_post, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @posts = Post.order('created_at DESC')
    respond_with(@posts)
  end

  def show
    respond_with(@post)
  end

  def new
    @post = Post.new
    respond_with(@post)
  end

  def edit
    respond_with(@post)
  end

  def create
    @post = Post.create(post_params)
    respond_with(@post)
  end

  def update
    @post.update(post_params)
    respond_with(@post)
  end

  def destroy
    @post.destroy
    respond_with(@post)
  end

  private

  def find_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:name, image_attributes: [:file])
  end
end