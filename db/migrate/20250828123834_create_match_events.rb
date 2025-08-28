class CreateMatchEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :match_events do |t|
      t.references :match, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :event_type, null: false
      t.integer :value, default: 1
      t.datetime :occurred_at

      t.timestamps
    end
    
    add_index :match_events, [:match_id, :event_type]
    add_index :match_events, [:player_id, :event_type]
  end
end