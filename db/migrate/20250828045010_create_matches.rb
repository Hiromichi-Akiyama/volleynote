class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
