class Admin::UniversitiesController < ApplicationController
  before_action :load_university, except: [:index, :new, :create]
  before_action :authorize

  def index
    @universities = University.all
    add_breadcrumb_index "universities"
    respond_to do |format|
      format.html
      format.json {
        render json: UniversitiesDatatable.new(view_context, @namespace)
      }
    end
  end

  def new
    @university = University.new
    add_breadcrumb_path "universities"
    add_breadcrumb_new "universities"
  end

  def create
    @university = University.new university_params
    respond_to do |format|
      if @university.save
        flash.now[:success] = flash_message "created"
        format.html {redirect_to admin_universities_path}
      else
        flash.now[:failed] = flash_message "not_created"
        format.html {render :new}
      end
      format.js
    end
  end

  def edit
    add_breadcrumb_path "universities"
    add_breadcrumb @university.name
    add_breadcrumb_edit "universities"
  end

  def update
    if @university.update_attributes university_params
      flash[:success] = flash_message "updated"
      redirect_to admin_universities_path
    else
      flash_message[:failed] = flash_message "not_updated"
      render :edit
    end
  end

  def destroy
    if @university.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:failed] = flash_message "not_deleted"
    end
    redirect_to :back
  end

  private
  def university_params
    params.require(:university).permit University::ATTRIBUTES_PARAMS
  end

  def load_university
    @university = University.find_by id: params[:id]
    unless @university
      redirect_to admin_universities_path
      flash[:alert] = flash_message "not_find"
    end
  end
end
