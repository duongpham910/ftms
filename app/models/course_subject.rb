class CourseSubject < ApplicationRecord
  acts_as_paranoid

  include PublicActivity::Model
  include RankedModel

  mount_uploader :image, ImageUploader

  ATTRIBUTES_PARAMS = [:subject_name, :image, :subject_description, :subject_content,
    :course_id, :row_order_position, :chatwork_room_id]
  PROJECT_ATTRIBUTES_PARAMS = [:project_id, course_subject_requirements_attributes:
    [:id, :project_requirement_id, :_destroy]]

  belongs_to :subject
  belongs_to :course
  belongs_to :project

  has_many :user_subjects, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :activities, as: :trackable, class_name: "PublicActivity::Activity", dependent: :destroy
  has_many :course_subject_requirements, dependent: :destroy
  has_many :project_requirements, through: :course_subject_requirement
  has_many :notifications, as: :trackable, dependent: :destroy

  after_create :init_objects

  accepts_nested_attributes_for :course_subject_requirements, allow_destroy: true
  accepts_nested_attributes_for :tasks, allow_destroy: true,
    reject_if: proc {|attributes| attributes["name"].blank?}

  scope :order_position, ->{rank :row_order}

  delegate :name, to: :course, prefix: true, allow_nil: true
  delegate :during_time, to: :subject, prefix: true, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true

  ranks :row_order, with_same: :course_id

  def finished?
    user_subjects.each do |user_subject|
      return false
    end
    true
  end

  def update_project_assign project_params
    CourseSubject.transaction do
      self.update_attributes project_params
      _rqm_ids = ProjectRequirement.where(project_id: project_id).pluck :id
      CourseSubjectRequirement.where("course_subject_id = ? AND project_requirement_id NOT IN (?)",
        id, _rqm_ids).destroy_all
      return true
    end
    false
  end

  private
  def init_objects
    init_objects_service = SubjectServices::InitCourseSubjectService.new self
    init_objects_service.perform
  end
end
