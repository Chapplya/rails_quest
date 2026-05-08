module QuestsHelper
  def quest_briefing_template(number)
    "quests/briefings/#{I18n.locale}/quest_#{number}"
  end

  def quest_two_step_path(step)
    quest_path(2, step: step)
  end
end
