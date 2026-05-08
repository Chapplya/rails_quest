class Quest2DataService
  # Don't edit this file, that is hardcoded values to match seeds and to avoid loading models before they are ready for Quest2.

  TASKS = [
    {
      step: 1,
      key: :all_agents,
      title: {
        ru: "Список всех агентов",
        en: "List all agents"
      },
      description: {
        ru: "Выведи список имен всех агентов из базы.",
        en: "Print the list of all agents from the database."
      },
      command: 'bin/rails runner "puts Quest2StudentService.all_agents"',
      expected_output: <<~TEXT.strip
        Atlas
        Echo
        Nova
        Viper
      TEXT
    },
    {
      step: 2,
      key: :all_missions,
      title: {
        ru: "Список всех миссий",
        en: "List all missions"
      },
      description: {
        ru: "Выведи список всех миссий в алфавитном порядке.",
        en: "Print the full mission list in alphabetical order."
      },
      command: 'bin/rails runner "puts Quest2StudentService.all_missions"',
      expected_output: <<~TEXT.strip
        Ember Trace
        Frozen Cipher
        Ghost Signal
        Glass Horizon
        Harbor Shield
        Iron Veil
        Midnight Relay
        Sapphire Run
        Silent Echo
        Solar Tide
      TEXT
    },
    {
      step: 3,
      key: :agents_with_missions,
      title: {
        ru: "Агенты и их миссии",
        en: "Agents and their missions"
      },
      description: {
        ru: "Покажи каждому агенту его миссии.",
        en: "Show each agent together with their missions."
      },
      command: 'bin/rails runner "puts Quest2StudentService.agents_with_missions"',
      expected_output: <<~TEXT.strip
        Atlas: Harbor Shield, Midnight Relay, Silent Echo
        Echo: Ghost Signal, Iron Veil, Sapphire Run, Solar Tide
        Nova: Frozen Cipher
        Viper: Ember Trace, Glass Horizon
      TEXT
    },
    {
      step: 4,
      key: :agents_with_missions_sorted_by_mission_count,
      title: {
        ru: "Агенты и миссии по убыванию числа миссий",
        en: "Agents and missions by mission count"
      },
      description: {
        ru: "Отсортируй агентов по убыванию числа миссий и выведи их списки. Если у агентов одинаковое число миссий, отсортируй их по имени.",
        en: "Sort agents by mission count descending and print their mission lists. If agents have the same number of missions, sort them by name."
      },
      command: 'bin/rails runner "puts Quest2StudentService.agents_with_missions_sorted_by_mission_count"',
      expected_output: <<~TEXT.strip
        Echo (4): Ghost Signal, Iron Veil, Sapphire Run, Solar Tide
        Atlas (3): Harbor Shield, Midnight Relay, Silent Echo
        Viper (2): Ember Trace, Glass Horizon
        Nova (1): Frozen Cipher
      TEXT
    },
    {
      step: 5,
      key: :agents_with_skills,
      title: {
        ru: "Агенты и их навыки",
        en: "Agents and their skills"
      },
      description: {
        ru: "Выведи список агентов и навыки каждого из них.",
        en: "Print agents together with all of their skills."
      },
      command: 'bin/rails runner "puts Quest2StudentService.agents_with_skills"',
      expected_output: <<~TEXT.strip
        Atlas: Cryptography, Recon
        Echo: Field Medicine, Infiltration, Recon
        Nova: Cryptography, Negotiation
        Viper: Infiltration, Negotiation, Recon
      TEXT
    },
    {
      step: 6,
      key: :skills_by_agent_count,
      title: {
        ru: "Навыки и количество агентов",
        en: "Skills and agent counts"
      },
      description: {
        ru: "Сгруппируй навыки по количеству агентов и выведи списки агентов, упорядоченные по имени.",
        en: "Group skills by agent count and show which agents possess them, sorted by name."
      },
      command: 'bin/rails runner "puts Quest2StudentService.skills_by_agent_count"',
      expected_output: <<~TEXT.strip
        Recon (3): Atlas, Echo, Viper
        Cryptography (2): Atlas, Nova
        Infiltration (2): Echo, Viper
        Negotiation (2): Nova, Viper
        Field Medicine (1): Echo
      TEXT
    }
  ].freeze

  class << self
    def tasks
      TASKS
    end

    def output_for(key)
      safely do
        Quest2StudentService.public_send(key)
      end
    rescue StandardError
      ""
    end

    private

    def safely
      return "" unless agents_ready?

      yield.to_s
    rescue StandardError
      ""
    end

    def agents_ready?
      model_ready?("Agent".safe_constantize, :agents) &&
        model_ready?("Mission".safe_constantize, :missions) &&
        model_ready?("Skill".safe_constantize, :skills) &&
        model_ready?("AgentSkill".safe_constantize, :agent_skills)
    end

    def model_ready?(klass, table_name)
      klass.present? && ActiveRecord::Base.connection.data_source_exists?(table_name)
    rescue StandardError
      false
    end
  end
end
