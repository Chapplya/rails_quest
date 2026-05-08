namespace :quest do
  def run_quest_check(number)
    test_file = Rails.root.join("test/quests/quest_#{number}_test.rb")
    abort "Test file not found: #{test_file}" unless test_file.exist?

    puts "\n\e[36m⚡ Rails Quests// Checking module #{number}...\e[0m\n\n"

    require "open3"
    output, _status = Open3.capture2e("bundle exec ruby -Itest #{test_file}")
    puts output

    if (m = output.match(/(\d+) runs?,\s*(\d+) assertions?,\s*(\d+) failures?,\s*(\d+) errors?/))
      total    = m[1].to_i
      failures = m[3].to_i + m[4].to_i
      passed   = total - failures
    else
      total = passed = failures = 0
    end

    result = {
      "passed"   => passed,
      "total"    => total,
      "failures" => failures,
      "success"  => failures == 0 && total > 0,
      "run_at"   => Time.current.iso8601
    }

    status_path = Rails.root.join("tmp/quest_status.json")
    all = status_path.exist? ? JSON.parse(status_path.read) : {}
    all[number.to_s] = result
    status_path.write(JSON.pretty_generate(all))

    color = result["success"] ? "\e[32m" : "\e[31m"
    puts "\n#{color}● Quest #{number}: #{passed}/#{total} passed\e[0m"
    puts "Results saved to tmp/quest_status.json"

    result
  end

  desc "Run tests for quest N and write results to tmp/quest_status.json. Usage: rails quest:check[1]"
  task :check, [ :number ] => :environment do |_, args|
    number = args[:number].to_i
    abort "Usage: rails quest:check[1..5]" unless (1..5).include?(number)

    run_quest_check(number)
  end

  desc "Print status table for all quests"
  task status: :environment do
    status_path = Rails.root.join("tmp/quest_status.json")
    test_results = status_path.exist? ? JSON.parse(status_path.read) : {}

    puts "\n\e[36m⚡ Rails Quests Recovery Terminal — Quest Status\e[0m"
    puts "─" * 60

    QuestProgress.ordered.each do |quest|
      meta    = quest.meta(locale: I18n.default_locale)
      tr      = test_results[quest.quest_number.to_s] || {}
      db_icon = quest.accepted? ? "\e[32m✓\e[0m" : quest.unlocked? ? "\e[36m🔓\e[0m" : "\e[90m🔒\e[0m"
      test_str = tr.any? ? "#{tr['passed']}/#{tr['total']} tests" : "not run"

      printf "  %s  Quest %-1d  %-20s  %-12s  %s\n",
        db_icon,
        quest.quest_number,
        meta[:module_name],
        quest.status.upcase,
        test_str
    end

    puts "─" * 60
    puts "  Run \e[36mrails quest:check[N]\e[0m to execute tests for quest N"
    puts "  Run \e[36mrails quest:accept[N]\e[0m to mark quest as accepted (CLI)\n\n"
  end

  desc "Accept quest N (CLI shortcut). Usage: rails quest:accept[1]"
  task :accept, [ :number ] => :environment do |_, args|
    number = args[:number].to_i
    quest  = QuestProgress.find_by(quest_number: number)
    abort "Quest #{number} not found." unless quest

    abort "Quest #{number} is locked." if quest.locked?

    result = run_quest_check(number)
    abort "Quest #{number} cannot be accepted until its tests pass." unless result["success"]

    status_path = Rails.root.join("tmp/quest_status.json")
    test_results = status_path.exist? ? JSON.parse(status_path.read) : {}
    tr = test_results[number.to_s] || {}
    tests_ok = tr["success"] == true

    unless tests_ok
      abort "Quest #{number} is not ready for acceptance (status: #{quest.status})."
    end

    quest.update!(status: "accepted", accepted_at: Time.current)
    QuestProgress.unlock_next_after(number)

    puts "\e[32m✓ Quest #{number} accepted!\e[0m"
    next_q = QuestProgress.find_by(quest_number: number + 1)
    puts "  Quest #{number + 1} unlocked." if next_q&.unlocked?
  end

  desc "Reset quest N back to unlocked. Usage: rails quest:reset[1]"
  task :reset, [ :number ] => :environment do |_, args|
    number = args[:number].to_i
    quest  = QuestProgress.find_by(quest_number: number)
    abort "Quest #{number} not found." unless quest

    quest.update!(status: "unlocked", accepted_at: nil)
    puts "\e[36m↩ Quest #{number} reset to unlocked.\e[0m"
  end
end
