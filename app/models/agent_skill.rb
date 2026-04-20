class AgentSkill < ApplicationRecord
  belongs_to :agent
  belongs_to :skill

  validates :agent_id, uniqueness: { scope: :skill_id }
end
