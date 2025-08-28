class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :team_name, :string
    add_column :users, :coach_name, :string
  end
end
