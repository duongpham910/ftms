class Course < ApplicationRecord
  include PublicActivity::Model
  include InitUserSubject
  mount_uploader :image, ImageUploader

  has_many :activities, as: :trackable, class_name: "PublicActivity::Activity", dependent: :destroy

  validate :check_end_date, on: [:create, :update]

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :programming_language_id, presence: true

  has_many :course_subjects, dependent: :destroy
  has_many :user_courses, dependent: :destroy
  has_many :user_subjects, dependent: :destroy
  has_many :users, through: :user_courses
  has_many :subjects, through: :course_subjects
  has_many :documents, as: :documentable
  has_many :notifications, as: :trackable, dependent: :destroy
  has_many :messages, as: :chat_room, dependent: :destroy

  belongs_to :programming_language
  belongs_to :location

  enum status: [:init, :progress, :finish]

  scope :recent, ->{order created_at: :desc}

  scope :active_course, ->{where status: "progress"}

  scope :created_between, ->start_date, end_date{where("DATE(created_at) >=
    ? AND DATE(created_at) <= ?", start_date, end_date)}
  scope :finished_between, ->start_date, end_date{where("DATE(updated_at) >=
    ? AND DATE(updated_at) <= ? AND status = #{statuses[:finish]}", start_date, end_date)}

  accepts_nested_attributes_for :user_courses, allow_destroy: true
  accepts_nested_attributes_for :documents,
    reject_if: proc {|attributes| attributes["content"].blank? && attributes["id"].blank?},
    allow_destroy: true

  USER_COURSE_ATTRIBUTES_PARAMS = [user_courses_attributes: [:id, :user_id, :_destroy]]
  COURSE_ATTRIBUTES_PARAMS = [:name, :image, :description,
    :programming_language_id, :location_id,
    :start_date, :end_date, documents_attributes:
    [:id, :name, :content, :description, :_destroy], subject_ids: []]

  delegate :name, to: :programming_language, prefix: true, allow_nil: true
  delegate :name, to: :location, prefix: true, allow_nil: true

  def active_user_courses_when_start_course
    user_courses.update_all active: true
  end

  def check_end_date
    unless start_date.nil?
      errors.add :end_date, I18n.t("error.wrong_end_date") if
        end_date < start_date
    end
  end

  def start_course current_user
    update_attributes status: :progress
    active_user_courses_when_start_course
    create_activity key: "course.start_course", owner: current_user
  end

  def finish_course current_user
    update_attributes status: :finish
    user_subjects.update_all status: UserSubject.statuses[:finish]
    create_activity key: "course.finish_course", owner: current_user
  end

  def reopen_course current_user
    update_attributes status: :init
    user_subjects.update_all status: UserSubject.statuses[:init]
    create_activity key: "course.reopen_course", owner: current_user
  end

  def load_trainers
    users.trainers
  end

  def load_trainees
    users.trainees
  end
end
