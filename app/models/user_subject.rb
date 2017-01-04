class UserSubject < ApplicationRecord
  include PublicActivity::Model
  include EstimateTime
  acts_as_paranoid
  include ChatworkApi

  alias_attribute :trainee, :user

  ATTRIBUTES_PARAMS = [:start_date, :end_date]

  belongs_to :user
  belongs_to :course
  belongs_to :trainee_course, foreign_key: :user_course_id
  belongs_to :course_subject
  has_many :user_tasks, dependent: :destroy
  has_many :notifications, as: :trackable, dependent: :destroy
  has_many :activities, as: :trackable, class_name: "PublicActivity::Activity", dependent: :destroy
  has_many :exams, dependent: :destroy
  has_many :trainee_evaluations, as: :targetable

  after_create :create_user_tasks

  scope :load_user_subject, ->user_id, course_id do
    where "user_id = ? AND course_id = ?", user_id, course_id
  end
  scope :load_users, ->status {where status: status}
  scope :not_finish, -> user_subjects {where.not(id: user_subjects)}
  scope :sort_by_course_subject, ->{joins(:course_subject).order("course_subjects.order asc")}
  scope :order_by_course_subject , ->{joins(:course_subject).order "course_subjects.row_order"}

  accepts_nested_attributes_for :user_tasks

  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :name, :id, :description, to: :subject, prefix: true, allow_nil: true
  delegate :name, to: :course, prefix: true, allow_nil: true
  delegate :link_github, :link_heroku, :chatwork_room_id, to: :course_subject, prefix: true,
    allow_nil: true

  enum status: [:init, :progress, :waiting, :finish]

  class << self
    def update_all_status status, current_user, course_subject

      if status == "start"
        user_subjects = load_users(statuses[:init]).each do |user_subject|
          user_subject.update_attributes status: statuses[:progress],
            start_date: Time.now, current_progress: user_subject.in_progress,
            end_date: user_subject.plan_end_date
        end
        key = "user_subject.start_all_subject"
      else
        user_subjects = load_users([:waiting, :progress]).each do |user_subject|
          user_subject.update_attributes status: statuses[:finish],
          user_end_date: Time.now, current_progress: user_subject.in_progress
        end
        user_subjects += load_users(statuses[:init]).each do |user_subject|
          user_subject.update_attributes status: statuses[:finished],
            current_progress: user_subject.in_progress
        end
        key = "user_subject.finish_all_subject"
      end
      course_subject.create_activity key: key,
        owner: current_user, recipient: course_subject.course
      user_subjects.each do |user_subject|
        if user_subject.previous_changes.present?
          user_ids = [current_user.id, user_subject.user_id].uniq
          Notifications::UserSubjectNotificationBroadCastJob.perform_now user_subject: user_subject,
            user: current_user, user_ids: user_ids, key: :change_status_up,
            parameters: status
        end
      end
    end
  end

  def update_status current_user, status
    row = status_before_type_cast
    column = UserSubject.statuses[status]
    update_info status: status, row: row, column: column, current_user: current_user
  end

  def subject
    course_subject.subject
  end

  def name
    course_subject.subject_name
  end

  def description
    course_subject.subject.description
  end

  def content
    course_subject.subject.content
  end

  def image_url
    course_subject.image_url
  end

  def is_of_user? user_param
    trainee == user_param
  end

  def percent_progress
    if start_date
      return 0 if start_date > Time.zone.today
      current_date = user_end_date
      current_date ||= Time.zone.today

      real_duration_time = end_date - start_date
      return 100 if real_duration_time <= 0

      user_current_time = (current_date - start_date).to_f
      percent = user_current_time * 100 / real_duration_time.to_f
      percent < 0 ? 0 : percent
    end
  end

  def create_user_task_if_create_task task
    user_tasks.create task: task, trainee: trainee
  end

  def in_progress
    trainee.user_subjects.update_all current_progress: false
    true
  end

  def check_current_progress
    user_subject = trainee.user_subjects.where(status: [:progress, :waiting])
      .order_desc(:updated_at).first
    user_subject ||= trainee.user_subjects.where(status: :finish)
      .order_desc(:updated_at).first
    user_subject.update_attributes(current_progress: true) if user_subject
    false
  end

  def locked?
    return true if exams.not_finished.size > 0 || lock_for_create_exam?

    recent_exams = exams.finish.order_desc(:created_at)
      .limit(Settings.exams.max_recent_exams).pluck(:created_at).reverse
    return false if recent_exams.size < Settings.exams.max_recent_exams

    duration = subject.subject_detail_time_of_exam.minutes.to_i
    current_time = (Time.zone.now - recent_exams.first).to_i

    if current_time < duration*4
      update_attributes lock_for_create_exam: true
      ResetPermissionExamJob.set(wait: Settings.exams.time_for_lock.hours)
        .perform_later self
      return true
    end
    false
  end

  def do_none_task?
    none_task = true
    user_tasks.each do |user_task|
      if user_task.user_task_finished_in_day?
        return none_task = false
      end
    end
    none_task
  end

  def plan_end_date
    working_day = Profile.find_by(user_id: user_id).try :working_day
    subject_time = course_subject.subject_during_time
    estimate_time = working_day ? (subject_time*5/working_day.to_f).to_i : (subject_time - 1)
    estimate_end_date estimate_time
  end

  private
  def create_user_tasks
    course_subject.tasks.each do |task|
      UserTask.find_or_create_by(user_subject_id: id,
        user_id: trainee_course.user_id, task_id: task.id)
    end
  end

  def update_info args
    arr = [
      [[], [0,2,1,3], [0,2,1,3], [0,0,0,3]],
      [[4,4,4,3], [], [1,1,1,1], [1,1,0,1]],
      [[4,4,4,3], [1,1,1,1], [], [1,1,0,1]],
      [[4,4,4,3], [1,1,4,3], [1,1,4,3], []]]
    actions = ["Time.now", "", "plan_end_date", "in_progress", "nil"]
    values = arr[args[:row]][args[:column]]

    if values
      if args[:row] == 0
        actions.map {|e| e == "in_progress" ? "check_current_progress" : e}
      end

      columns = %w(start_date end_date user_end_date current_progress)
      params = {status: args[:status]}

      values.each_with_index do |key, index|
        unless actions[key].blank?
          params[columns[index]] = eval(actions[key]).to_s
        end
      end
      user_subject_params = ActionController::Parameters.new params
      update_attributes user_subject_params

      if previous_changes.present?
        activity_key = "user_subject.change_status"
        old_status = UserSubject.statuses.key args[:row]
        new_status = UserSubject.statuses.key args[:column]
        parameters = {old_status: old_status, new_status: new_status}
        create_activity key: activity_key, owner: args[:current_user],
          recipient: trainee, parameters: parameters
        user_ids = [args[:current_user].id, user_id].uniq

        notification_key = args[:row] > args[:column] ? :change_status_down : :change_status_up
        Notifications::UserSubjectNotificationBroadCastJob.perform_now user_subject: self,
          user: args[:current_user], user_ids: user_ids, key: notification_key,
          parameters: new_status
      end
    end
  end
end
