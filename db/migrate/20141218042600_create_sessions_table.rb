class CreateSessionsTable < ActiveRecord::Migration
  def change
    create_table :sessions, :id => false do |t|
      t.string  :id
      t.string  :token
      t.boolean :current, :default => true
      t.string  :username
      t.string  :email
      t.string  :initials
      t.string  :name

    end

    add_index :sessions, :current
  end
end
