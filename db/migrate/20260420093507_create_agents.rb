class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.string :codename, null: false
      t.integer :level, null: false
      t.boolean :active, null: false

      t.timestamps
    end

    add_index :agents, :codename, unique: true
    add_check_constraint :agents, "level BETWEEN 1 AND 10", name: "agents_level_between_1_and_10"
  end
end
