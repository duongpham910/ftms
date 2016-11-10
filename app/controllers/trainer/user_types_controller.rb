class Trainer::UserTypesController < ApplicationController
  before_action :authorize
  before_action :load_user_type, only: [:edit, :update, :destroy]

  def index
    @user_types = UserType.all
    @user_type = UserType.new
    add_breadcrumb_index "user_types"
  end

  def new
    @user_type = UserType.new
    add_breadcrumb_path "user_types"
    add_breadcrumb_new "user_types"
  end

  def create
    @user_type = UserType.new user_type_params
    respond_to do |format|
      if @user_type.save
        flash.now[:success] = flash_message "created"
        format.html {redirect_to trainer_user_types_path}
      else
        flash.now[:failed] = flash_message "not_created"
        format.html {render :new}
      end
      format.js
    end
  end

  def edit
    add_breadcrumb_path "user_types"
    add_breadcrumb @user_type.name
    add_breadcrumb_edit "user_types"
  end

  def update
    if @user_type.update_attributes user_type_params
      flash[:success] = flash_message "updated"
      redirect_to trainer_user_types_path
    else
      flash[:failed] = flash_message "not_update"
      render :edit
    end
  end

  def destroy
    if @user_type.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:failed] = flash_message "not_deleted"
    end
    redirect_to :back
  end

  private
  def user_type_params
    params.require(:user_type).permit UserType::ATTRIBUTES_PARAMS
  end

  def load_user_type
    @user_type = UserType.find_by id: params[:id]
    unless @user_type
      redirect_to trainer_user_user_types_path
      flash[:alert] = flash_message "not_find"
    end
  end
end
