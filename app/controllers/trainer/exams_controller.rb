class Trainer::ExamsController < ApplicationController
  include FilterData
  before_action :authorize, only: :index
  before_action :load_filter, only: :index

  def index
    @exams = Exam.finish.includes :user, user_subject: [:course, course_subject: :subject]
    @filter_data_user = @filter_service.user_filter_data
    @exam_presenters = ExamPresenter.new(@exams, @namespace).render
    add_breadcrumb_index "exams"
  end

  def show
  end
end
