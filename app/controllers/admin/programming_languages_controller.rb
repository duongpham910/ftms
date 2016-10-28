class Admin::ProgrammingLanguagesController < ApplicationController
  load_and_authorize_resource

  def index
    @programming_language = ProgrammingLanguage.new
  end

  def create
    respond_to do |format|
      if @programming_language.save
        flash.now[:success] = flash_message "created"
        format.html{redirect_to admin_programming_languages_path}
      else
        flash.now[:failed] = flash_message "not_created"
        format.html{render :new}
      end
      format.js
    end
  end

  def edit
  end

  def update
    if @programming_language.update_attributes programming_language_params
      flash[:success] = "updated"
    else
      flash[:failed] = "not_updated"
      render :edit
    end
    redirect_to :back
  end

  def destroy
    if @programming_language.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:failed] = flash_message "not_deleted"
    end
    redirect_to :back
  end

  private
  def programming_language_params
    params.require(:programming_language).permit ProgrammingLanguage::ATTRIBUTES_PARAMS
  end
end
