class QuestsController < ApplicationController
  before_action :set_quest, only: %i[show]

  def index
    @quests = QuestProgress.ordered
    @test_results = load_test_results
  end

  def show
    redirect_to root_path, alert: t("quests.show.locked_alert") and return if @quest.locked?

    @results = load_test_results[@quest.quest_number.to_s] || {}
    prepare_quest_payload
  end


  private

  def set_quest
    @quest = QuestProgress.find_by!(quest_number: params[:number])
  end

  def load_test_results
    path = Rails.root.join("tmp/quest_status.json")
    return {} unless path.exist?

    JSON.parse(path.read)
  rescue JSON::ParserError
    {}
  end

  def prepare_quest_payload
    case @quest.quest_number
    when 2
      prepare_quest_two_payload
    end
  end

  def prepare_quest_two_payload
    @quest_two_tasks = Quest2DataService.tasks.map do |task|
      actual_output = Quest2DataService.output_for(task[:key])

      task.merge(
        actual_output: actual_output,
        solved: normalized_output(actual_output) == normalized_output(task[:expected_output])
      )
    end

    @quest_two_current_step = requested_quest_two_step
    accessible_step = first_unsolved_quest_two_step

    if @quest_two_current_step > accessible_step
      redirect_to quest_path(@quest.quest_number, step: accessible_step), alert: t("quests.quest_two.step_locked") and return
    end

    @quest_two_current_task = @quest_two_tasks.find { |task| task[:step] == @quest_two_current_step }
    @quest_two_accessible_step = accessible_step
  end

  def requested_quest_two_step
    step = params[:step].presence&.to_i
    return first_unsolved_quest_two_step if step.blank? || step <= 0

    [ step, Quest2DataService.tasks.size ].min
  end

  def first_unsolved_quest_two_step
    @quest_two_tasks.find { |task| !task[:solved] }&.fetch(:step) || @quest_two_tasks.size
  end

  def normalized_output(output)
    output.to_s.lines.map(&:rstrip).join("\n").strip
  end
end
