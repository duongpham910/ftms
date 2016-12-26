class Supports::UserSupport
  attr_reader :user, :current_user

  def initialize user
    @user = user
  end

  def activities
    @activities ||= PublicActivity::Activity.includes(:owner, :trackable)
      .user_activities(@user.id).recent.limit(20).decorate
  end

  def user_courses
    @user_courses ||= @user.trainee_courses.includes(user_subjects: [:course,
      :trainee_evaluations, :exams, {user_tasks: :task}, course_subject: :subject])
  end

  def finished_courses
    @finished_courses ||= user_courses.finish
  end

  def inprogress_course
    @inprogress_course ||= user_courses.find {|user_course| user_course.progress?}
  end

  def user_subjects
    @user_subjects ||= inprogress_course.user_subjects.includes([course_subject:
      :subject], user_tasks: :task).order_by_course_subject if inprogress_course
  end

  def note
    @note ||= Note.new
  end

  def managers
    @managers ||= User.not_trainees
  end

  def trainers
    @trainers ||= User.trainers.includes :profile
  end

  def stage
    @stage ||= @user.new_record? ? Stage.find_by(name: "In education") : @user.profile.stage
  end

  %w(roles universities languages statuses trainee_types locations)
    .each do |objects|
    define_method objects do
      instance_variable_set "@#{objects}", objects.classify.constantize.all
    end
  end

  %w(location university trainee_type language status).each do |object|
    define_method object do
      instance_variable_set "@#{object}", object.classify.constantize.new
    end
  end

  def fa_icon index
    case index
    when 1
      "fa-star-o"
    when 2
      "fa-sun-o"
    when 3
      "fa-check-circle-o"
    when 4
      "fa-moon-o"
    else
      "fa-smile-o"
    end
  end

  def fa_background index
    case index
    when 1
      "bg-blue"
    when 2
      "bg-green"
    when 3
      "bg-orange"
    when 4
      "bg-blue"
    else
      "bg-red"
    end
  end

  def background_icon index
    case index
    when 1
      "primary"
    when 2
      "success"
    when 3
      "warning"
    when 4
      "info"
    else
      "danger"
    end
  end
end
