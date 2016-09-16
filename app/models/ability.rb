class Ability
  include CanCan::Ability

  def initialize user, namespace
    @user = user
    if (namespace == Settings.namespace_roles.admin || namespace == "object") && @user.is_admin?
      can :manage, :all
    elsif (namespace == Settings.namespace_roles.trainer || namespace == "object") && @user.is_trainer?
      user_role_permissions @user, Settings.role_types.trainer
    elsif user.is_trainee?
      user_role_permissions @user, Settings.role_types.trainee
    end
    can [:read, :update], User, id: @user.id
  end

  private
  def user_role_permissions user, role_type
    Permission.joins(:role).where(role_id: user.roles, "roles.role_type": role_type)
      .pluck(:model_class, :action).uniq.each do |permission|
      model_class = permission.first.constantize
      action = permission.second.to_sym
      can action, model_class do |model|
        if model_class == "Course"
          @user.in_course? model.id
        elsif model_class == "User"
          courses = @user.user_courses.pluck :course_id
          model.in_course? courses
        else
          true
        end
      end
    end
  end
end
