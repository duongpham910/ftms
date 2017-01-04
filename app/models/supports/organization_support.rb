class Supports::OrganizationSupport
  def initialize args = {}
  end

  def organization location
    organization_chart_data = Hash.new
    @trainee_profiles = trainee_profiles_in_ducation location
    trainer_profiles = trainer_profiles location

    trainer_profiles.each do |trainer_profile|
      organization_chart_data[trainer_profile.user] = subjects trainer_profile
    end
    organization_chart_data
  end

  def away_trainees location
    trainee_profiles = trainee_profiles location
    trainee_profiles.collect do |profile|
      if profile.stage_id == away_stage.id
        profile.user
      end
    end.uniq.delete_if {|x| x.nil?}
  end

  private
  def trainee_profiles location
    location.profiles.select do |profile|
      profile.user.is_a? Trainee
    end
  end

  def away_stage
    @away ||= Stage.find_by name: "Away"
  end

  def in_education_stage
    @in_education ||= Stage.find_by name: "In education"
  end

  def trainee_profiles_in_ducation location
    trainee_profiles = trainee_profiles location
    trainee_profiles.select do |profile|
      profile.stage_id == in_education_stage.id
    end
  end

  def trainer_profiles location
    location.profiles.select do |profile|
      profile.user.is_a?(Trainer) && profile.stage_id == in_education_stage.id
    end
  end

  def trainee_of trainer_profile
    @trainee_profiles.select do |trainee_profile|
      trainee_profile.user.trainer_id == trainer_profile.user_id
    end
  end

  def subjects trainer_profile
    trainee_profiles = trainee_of trainer_profile
    subjects = Hash.new
    subjects["free_trainees"] = Array.new
    trainee_profiles.each do |trainee_profile|
      user_subject = trainee_profile.user.user_subjects.find{|user_subject| user_subject.current_progress?}
      if user_subject
        subjects[user_subject.subject] ||= Array.new
        subjects[user_subject.subject] << trainee_profile
      else
        subjects["free_trainees"] << trainee_profile
      end
    end
    subjects
  end
end
