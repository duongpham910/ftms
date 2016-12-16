class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up
    remove_index :taggings, :tag_id if index_exists?(:taggings, :tag_id)
    remove_index :taggings, [:taggable_id, :taggable_type, :context]

    add_index :tags, :name, unique: true
    add_index :taggings, [:tag_id, :taggable_id, :taggable_type, :context,
      :tagger_id, :tagger_type], unique: true, name: "taggings_idx"
  end

  def self.down
    remove_index :tags, :name
    remove_index :taggings, name: "taggings_idx"

    add_index :taggings, :tag_id unless index_exists?(:taggings, :tag_id)
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
