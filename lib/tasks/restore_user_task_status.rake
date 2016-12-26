require "json"

namespace :db do
  desc "Restore user_task_status"
  # Only run after remove table user_task_histories
  task restore_user_task_statuses: :environment do
    path = "/tmp/user_task_status.txt"
    if File.exists?(File.expand_path path)
      puts "Restore user_task's status from file"
      str = File.read path
      content = JSON.load str
      content.each do |user_task|
        task = UserTask.find_by id: user_task[0]
        status = case user_task[1]
          when 1
            2
          when 2
            3
          else
            0
          end
        task.update_attributes status: status
      end
    else
      puts "File could not found!"
    end
  end
end
