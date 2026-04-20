class Skill < ApplicationRecord
  has_many :agent_skills, dependent: :destroy
  has_many :agents, through: :agent_skills

  validates :name, presence: true, uniqueness: true
end
