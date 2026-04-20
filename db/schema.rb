# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_20_093516) do
  create_table "agent_skills", force: :cascade do |t|
    t.integer "agent_id", null: false
    t.datetime "created_at", null: false
    t.integer "skill_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "skill_id"], name: "index_agent_skills_on_agent_id_and_skill_id", unique: true
    t.index ["agent_id"], name: "index_agent_skills_on_agent_id"
    t.index ["skill_id"], name: "index_agent_skills_on_skill_id"
  end

  create_table "agents", force: :cascade do |t|
    t.boolean "active", null: false
    t.string "codename", null: false
    t.datetime "created_at", null: false
    t.integer "level", null: false
    t.datetime "updated_at", null: false
    t.index ["codename"], name: "index_agents_on_codename", unique: true
    t.check_constraint "level BETWEEN 1 AND 10", name: "agents_level_between_1_and_10"
  end

  create_table "missions", force: :cascade do |t|
    t.integer "agent_id", null: false
    t.datetime "created_at", null: false
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_missions_on_agent_id"
    t.check_constraint "status IN ('assigned', 'in_progress', 'completed')", name: "missions_status_valid_values"
  end

  create_table "quest_progresses", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.integer "quest_number", null: false
    t.string "status", default: "locked", null: false
    t.datetime "unlocked_at"
    t.datetime "updated_at", null: false
    t.index ["quest_number"], name: "index_quest_progresses_on_quest_number", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_skills_on_name", unique: true
  end

  add_foreign_key "agent_skills", "agents"
  add_foreign_key "agent_skills", "skills"
  add_foreign_key "missions", "agents"
end
