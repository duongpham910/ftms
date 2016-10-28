class Admin::StatusesController < ApplicationController
  load_and_authorize_resource except: :show

  def index
    @status = Status.new
    add_breadcrumb_index "statuses"
  end

  def new
    add_breadcrumb_path "statuses"
    add_breadcrumb_new "statuses"
  end

  def create
    respond_to do |format|
      if @status.save
        flash.now[:success] = flash_message "created"
        format.html{redirect_to admin_statuses_path}
      else
        flash.now[:failed] = flash_message "not_created"
        format.html{render :new}
      end
      format.js
    end
  end

  def edit
    add_breadcrumb_path "statuses"
    add_breadcrumb @status.name
    add_breadcrumb_edit "statuses"
  end

  def update
    if @status.update_attributes status_params
      flash[:success] = flash_message "updated"
      redirect_to admin_statuses_path
    else
      flash_message[:failed] = flash_message "not_updated"
      render :edit
    end
  end

  def destroy
    if @status.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:failed] = flash_message "not_deleted"
    end
    redirect_to :back
  end

  private
  def status_params
    params.require(:status).permit Status::ATTRIBUTES_PARAMS
  end
end
