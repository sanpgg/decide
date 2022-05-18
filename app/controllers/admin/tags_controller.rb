class Admin::TagsController < Admin::BaseController
  before_action :find_tag, only: [:edit, :update, :destroy]

  respond_to :html, :js

  def index
    @success_button = "Crear tema"
    @tags = ActsAsTaggableOn::Tag.category.page(params[:page])
    @tag  = ActsAsTaggableOn::Tag.category.new
  end

  def create
    ActsAsTaggableOn::Tag.category.create(tag_params)
    redirect_to admin_tags_path
  end

  def edit
    @success_button = "Editar tema"
  end

  def update

    if @tag.update(tag_params)
      redirect_to admin_tags_path, notice: 'Tema actualizado correctamente.'
    else
      render :edit
    end

  end

  def destroy
    @tag.destroy
    redirect_to admin_tags_path
  end

  private

    def tag_params
      params.require(:tag).permit(:name, :description)
    end

    def find_tag
      @tag = ActsAsTaggableOn::Tag.category.find(params[:id])
    end

end
