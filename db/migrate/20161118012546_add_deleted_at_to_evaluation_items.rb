class AddDeletedAtToEvaluationItems < ActiveRecord::Migration[5.0]
  def change
    add_column :evaluation_items, :deleted_at, :datetime
    add_index :evaluation_items, :deleted_at
    add_column :evaluation_standards, :deleted_at, :datetime
    add_index :evaluation_standards, :deleted_at
    add_column :evaluation_groups, :deleted_at, :datetime
    add_index :evaluation_groups, :deleted_at
  end
end
