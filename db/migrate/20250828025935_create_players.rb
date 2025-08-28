# db/migrate/xxx_create_players.rb
class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :number, null: false
      t.string :position
      t.integer :spike_attempts, default: 0
      t.integer :spike_kills, default: 0
      t.integer :recv_attempts, default: 0
      t.integer :recv_successes, default: 0
      t.integer :serve_attempts, default: 0
      t.integer :serve_effects, default: 0
      t.integer :serve_points, default: 0

      t.timestamps
    end
    
    add_index :players, [:user_id, :number], unique: true
  end
end