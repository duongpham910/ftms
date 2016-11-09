class UserPolicy < ApplicationPolicy
  attr_reader :user, :controller, :action, :user_functions, :record

  def initialize user, args
    @user = user
    @controller_name = args[:controller]
    @action = args[:action]
    @user_functions = args[:user_functions]
    @record = args[:record]
  end

  def show?
    @user = @record
  end

  def edit?
    if @user = @record
      User::USER_ATTRIBUTES_PARAMS
    end
  end

  def update?
    edit?
  end
end
