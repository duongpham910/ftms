class Admin::ProgramsController < ApplicationController
  include FilterData

  before_action :authorize
  before_action :find_program, only: [:edit, :update, :show]
  before_action :find_parent_program, only: :new
  before_action :load_data, only: [:edit, :new]

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: ProgramsDatatable.new(view_context, @namespace)
      }
    end
  end

  def new
  end

  def create
    @program = Program.new params_programs
    if @program.save
      flash[:success] = flash_message "created"
      redirect_to admin_programs_path
    else
      load_data
      render :new
    end
  end

  def show
    @supports = Supports::CourseSupport.new namespace: @namespace,
      filter_service: load_filter, program: @program
  end

  def edit
  end

  def update
    if @program.update_attributes params_programs
      flash[:success] = flash_message "updated"
      redirect_to admin_programs_path
    else
      load_data
      render :edit
    end
  end

  def destroy
    if @program.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:error] = flash_message "not_deleted"
    end
    redirect_to admin_programs_path
  end

  private
  def params_programs
    params.require(:program).permit Program::ATTRIBUTES_PARAMS
  end

  def load_data
    @program_supports = Supports::ProgramSupport.new program: @program
  end

  def find_program
    @program = Program.find_by id: params[:id]
    unless @program
      flash[:alert] = flash_message "not_find"
      redirect_to admin_programs_path
    end
  end

  def find_parent_program
    if params[:parent_id]
      parent_program = Program.find_by id: params[:parent_id]
      if parent_program
        @program = parent_program.children.new program_type: parent_program.program_type
      else
        flash[:alert] = flash_message "not_find"
        redirect_to admin_programs_path
      end
    else
      @program = Program.new
    end
  end
end
