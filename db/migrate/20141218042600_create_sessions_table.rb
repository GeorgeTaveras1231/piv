class CreateSessionsTable < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string  :token
      t.boolean :current, :default => true
      t.string  :user
      t.string  :name

    end

    add_index :sessions, :current
  end
end
