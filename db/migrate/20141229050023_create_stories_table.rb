class CreateStoriesTable < ActiveRecord::Migration
  def change
    create_table :stories, :id => false do |t|
      t.string :id
      t.string :name
      t.boolean :current
      t.string :current_state
      t.integer :estimate
      t.text :description
      t.string :story_type
      t.belongs_to :project
    end
  end
end
