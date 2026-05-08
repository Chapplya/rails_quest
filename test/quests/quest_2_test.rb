require_relative "quest_helper"

class Quest2IntelSeedTest < QuestTestCase
  TEST_SCOPE = %i[tests quest_2].freeze

  setup do
    Rails.application.load_seed

    QuestProgress.find_or_create_by!(quest_number: 1) do |quest|
      quest.status = "accepted"
      quest.accepted_at = Time.current
    end

    QuestProgress.find_or_create_by!(quest_number: 2) do |quest|
      quest.status = "unlocked"
      quest.unlocked_at = Time.current
    end
  end

  test I18n.t(:service_matches_reference, scope: TEST_SCOPE) do
    Quest2DataService.tasks.each do |task|
      assert_equal normalized_output(task[:expected_output]),
        normalized_output(Quest2StudentService.public_send(task[:key])),
        I18n.t(:step_mismatch, scope: TEST_SCOPE, step: task[:step])
    end
  end


  private

  def normalized_output(output)
    output.to_s.lines.map(&:rstrip).join("\n").strip
  end
end
