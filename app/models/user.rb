class User < ApplicationRecord
  acts_as_paranoid
  acts_as_reader
  mount_uploader :avatar, ImageUploader

  QUERY = "SELECT users.id, users.name, user_course_id FROM users LEFT JOIN (
      SELECT user_courses.id user_course_id, users.id user_id FROM users LEFT JOIN user_courses
      ON users.id = user_courses.user_id
      WHERE user_courses.course_id = :course_id
    ) t ON users.id = t.user_id
    WHERE id NOT IN (SELECT user_id
      FROM user_courses, courses WHERE user_courses.course_id = courses.id
      AND (
        (courses.status = 1
          AND user_courses.deleted_at IS NULL
          AND user_courses.status = 1
          AND user_courses.type = 'TraineeCourse'
          AND courses.id <> :course_id)
        OR (user_courses.deleted_at IS NULL AND course_id = :course_id)
      )
    )"

  ATTRIBUTES_PARAMS = [:name, :email, :password,
    :password_confirmation, :avatar, :trainer_id, :chatwork_id,
    :profile_id, :start_training_date, :leave_date, :finish_training_date,
    :ready_for_project, :contract_date, :naitei_company,
    :trainee_type_id, :university_id, :language_id, :user_progress_id,
    :status_id, :location_id, :graduation, :working_day, :staff_code,
    :join_div_date, :stage_id, :away_date, :comeback_date, role_ids: []]

  USER_ATTRIBUTES_PARAMS = [:name, :password, :password_confirmation, :avatar,
    profile_attributes: [:working_day, :graduation, :university_id]]

  TRAINER_ATTRIBUTES_PARAMS = [:name, :trainer_id,
    profile_attributes: [:working_day, :graduation, :university_id,
    :language_id, :user_progress_id,
    :status_id, :location_id]]

  attr_accessor :current_role

  belongs_to :role
  belongs_to :trainer, class_name: User.name, foreign_key: :trainer_id

  has_one :profile, dependent: :destroy

  has_many :trainees, class_name: User.name, foreign_key: :trainer_id
  has_many :notifications, dependent: :destroy
  has_many :user_notifications, dependent: :destroy
  has_many :senders, class_name: Conversation.name, foreign_key: :sender_id,
    dependent: :destroy
  has_many :receivers, class_name: Conversation.name, foreign_key: :receiver_id,
    dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :feed_backs, dependent: :destroy
  has_many :track_logs, dependent: :destroy
  has_many :filters, dependent: :destroy
  has_many :user_functions, dependent: :destroy
  has_many :trainer_functions, dependent: :destroy
  has_many :trainee_functions, dependent: :destroy
  has_many :admin_functions, dependent: :destroy
  has_many :functions, through: :user_functions
  has_many :programs, through: :trainer_programs
  has_many :user_courses, dependent: :destroy
  has_many :courses, through: :user_courses
  has_many :trainer_courses, dependent: :destroy
  has_many :trainee_courses, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :trainee_evaluations, dependent: :destroy
  has_many :user_tasks, dependent: :destroy
  has_many :user_subjects, dependent: :destroy
  has_many :exams, dependent: :destroy
  has_many :likes, dependent: :destroy

  has_many :active_note, class_name: Note.name, foreign_key: :author_id
  has_many :passive_note, class_name: Note.name, foreign_key: :user_id

  validates :name, presence: true, uniqueness: true
  validates_confirmation_of :password

  scope :available_of_course, ->course_id{find_by_sql [QUERY, course_id: course_id]}
  scope :trainee_roles, ->{joins(user_roles: :role)
    .where("roles.role_type = ?", Role.role_types[:trainee])}
  scope :trainers, ->{joins(user_roles: :role)
    .where("roles.role_type = ?", Role.role_types[:trainer])}
  scope :admin_roles, ->{joins(user_roles: :role)
    .where("roles.role_type = ?", Role.role_types[:admin])}
  scope :find_course, ->course{joins(:user_courses)
    .where("user_courses.course_id in (?)", course).distinct}
  scope :not_trainees, ->{where.not type: "Trainee"}
  scope :by_location, ->location_id{
    joins(:profile).where("profiles.location_id = ?", location_id)
  }
  scope :created_between, ->start_date, end_date{where("DATE(created_at) >=
    ? AND DATE(created_at) <= ?", start_date, end_date)}
  scope :by_trainer, ->trainer_id{where trainer_id: trainer_id}
  scope :free_group, ->{where.not id: GroupUser.select(:user_id)}
  scope :free_and_in_group, ->group_id{where.not id: GroupUser
    .where.not(group_id: group_id).select(:user_id)}

  before_validation :set_password

  accepts_nested_attributes_for :profile
  accepts_nested_attributes_for :user_functions, allow_destroy: true

  delegate :id, :name, to: :role, prefix: true, allow_nil: true
  delegate :location_id, to: :profile, prefix: true, allow_nil: true
  delegate :name, to: :user_task, prefix: true, allow_nil: true
  delegate :working_day, to: :profile, prefix: true, allow_nil: true
  delegate :graduation, to: :profile, prefix: true, allow_nil: true

  devise :database_authenticatable, :rememberable, :trackable, :validatable,
    :recoverable
  enum current_role_type: {admin: 0, trainer: 1, trainee: 2}

  def total_done_tasks user, course
    done_tasks = UserSubject.load_user_subject(user.id, course.id).map(&:user_tasks).flatten.count
  end

  def owner_course course
    return course.user_courses.find_by(supervisor_id: self.id) ? true :false
  end

  def leader_course course
    return course.user_courses.find_by(leader_id: self.id) ? true :false
  end

  %w(admin trainee trainer).each do |trainee_type|
    define_method "is_#{trainee_type}?" do
      if current_role.present?
        current_role.include? eval("Settings.namespace_roles.#{trainee_type}")
      else
        self.has_role? trainee_type
      end
    end
  end

  def in_course? course
    user_courses.exists? course_id: course
  end

  def current_progress
    user_subjects.find {|user_subject| user_subject.current_progress?}
  end

  def role_type_avaiable
    self.roles.order(:role_type).map(&:role_type).uniq
  end

  def has_role? role
    role = Role.find_by name: role
    self.role_type_avaiable.include? role
  end

  def has_function? controller, action, role
    type = (role+"Function").classify.constantize
    user_functions.has_function(controller, action, type).any?
  end

  def like? target
    like = target.likes.find_by user_id: id
  end

  private
  def set_password
    if new_record?
      self.password = Settings.default_password
      self.password_confirmation = Settings.default_password
    end
  end

  def password_required?
    new_record? ? super : false
  end
end
