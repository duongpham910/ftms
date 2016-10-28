module NotificationHelper
  def notification_content notification
    trackable = notification.trackable

    if trackable.class.name == "Course"
      data = "Course: #{trackable.name}: "
    elsif trackable.class.name == "UserSubject"

      content = t("layouts.subject") << notification.user_name
      content << t("notifications.keys.#{notification.key}",
        data: notification.trackable.course_subject.subject_name)
      content << notification.parameters
    end
    content
  end

  def notification_image notification
    trackable = notification.trackable

    if trackable.class.name == "Course"
      image_object = trackable
    elsif trackable.class.name == "UserSubject"
      image_object = trackable.course_subject
    end

    set_image image_object, Settings.image_size_40
  end

  def not_seen_notification
    if (size = current_user.user_notifications.not_seen.size) > 0
      size
    end
  end

  def notification_link notification
    trackable = notification.trackable
    if trackable.class.name == "Course"
      trackable
    elsif trackable.class.name == "UserSubject"
      user_course_subject_path trackable.user_course_id,
        trackable.course_subject.subject_id
    end
  end
end
