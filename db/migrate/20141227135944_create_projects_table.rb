class CreateProjectsTable < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.boolean :current, :default => false
      t.string :original_id
      t.belongs_to :session
    end
  end
end
