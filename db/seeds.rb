# ============================================================
#  RailsOS — Quest Progress seeds
#  Initialise 5 quests: Quest 1 unlocked, 2-5 locked
# ============================================================

QuestProgress.find_or_create_by!(quest_number: 1) do |q|
  q.status      = "unlocked"
  q.unlocked_at = Time.current
end

(2..5).each do |n|
  QuestProgress.find_or_create_by!(quest_number: n) do |q|
    q.status = "locked"
  end
end

puts "Rails Quests initialised. Quest 1 — UNLOCKED. Quests 2-5 — LOCKED."

def quest_table_exists?(table_name)
  ActiveRecord::Base.connection.data_source_exists?(table_name)
rescue StandardError
  false
end

agent_class = "Agent".safe_constantize
mission_class = "Mission".safe_constantize
skill_class = "Skill".safe_constantize
agent_skill_class = "AgentSkill".safe_constantize

required_tables = %i[agents missions skills agent_skills]
required_classes = [ agent_class, mission_class, skill_class, agent_skill_class ]

if required_classes.all? && required_tables.all? { |table_name| quest_table_exists?(table_name) }
  agents_data = [
    { codename: "Atlas", level: 6, active: true },
    { codename: "Echo", level: 4, active: true },
    { codename: "Nova", level: 5, active: false },
    { codename: "Viper", level: 9, active: true }
  ]

  skills_data = [
    { name: "Cryptography", category: "analysis" },
    { name: "Field Medicine", category: "support" },
    { name: "Infiltration", category: "stealth" },
    { name: "Negotiation", category: "diplomacy" },
    { name: "Recon", category: "intel" }
  ]

  missions_data = [
    { title: "Harbor Shield", status: "assigned", agent_codename: "Atlas" },
    { title: "Midnight Relay", status: "in_progress", agent_codename: "Atlas" },
    { title: "Silent Echo", status: "completed", agent_codename: "Atlas" },
    { title: "Ghost Signal", status: "completed", agent_codename: "Echo" },
    { title: "Iron Veil", status: "assigned", agent_codename: "Echo" },
    { title: "Sapphire Run", status: "completed", agent_codename: "Echo" },
    { title: "Solar Tide", status: "in_progress", agent_codename: "Echo" },
    { title: "Frozen Cipher", status: "completed", agent_codename: "Nova" },
    { title: "Ember Trace", status: "assigned", agent_codename: "Viper" },
    { title: "Glass Horizon", status: "completed", agent_codename: "Viper" }
  ]

  agent_skills_data = {
    "Atlas" => [ "Cryptography", "Recon" ],
    "Echo" => [ "Field Medicine", "Infiltration", "Recon" ],
    "Nova" => [ "Cryptography", "Negotiation" ],
    "Viper" => [ "Infiltration", "Negotiation", "Recon" ]
  }

  seeded_agents = agents_data.each_with_object({}) do |attributes, result|
    result[attributes[:codename]] = agent_class.find_or_initialize_by(codename: attributes[:codename]).tap do |agent|
      agent.assign_attributes(level: attributes[:level], active: attributes[:active])
      agent.save!
    end
  end

  seeded_skills = skills_data.each_with_object({}) do |attributes, result|
    result[attributes[:name]] = skill_class.find_or_initialize_by(name: attributes[:name]).tap do |skill|
      skill.assign_attributes(category: attributes[:category])
      skill.save!
    end
  end

  missions_data.each do |attributes|
    mission_class.find_or_initialize_by(title: attributes[:title]).tap do |mission|
      mission.assign_attributes(
        status: attributes[:status],
        agent: seeded_agents.fetch(attributes[:agent_codename])
      )
      mission.save!
    end
  end

  agent_skills_data.each do |codename, skill_names|
    agent = seeded_agents.fetch(codename)

    skill_names.each do |skill_name|
      agent_skill_class.find_or_create_by!(
        agent: agent,
        skill: seeded_skills.fetch(skill_name)
      )
    end
  end

  puts "Quest 2 data seeded: #{seeded_agents.size} agents, #{missions_data.size} missions, #{seeded_skills.size} skills."
else
  puts "Quest 2 data skipped: complete Quest 1 models and migrations first."
end
