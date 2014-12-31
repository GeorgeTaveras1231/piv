class CreateProjectsTable < ActiveRecord::Migration
  def change
    create_table :projects, :id => false do |t|
      t.string :id
      t.string :name
      t.boolean :current, :default => false
      t.belongs_to :session
    end
  end
end
