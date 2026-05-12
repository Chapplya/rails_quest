# frozen_string_literal: true

# Сервис квеста 2: готовые выборки из БД через ActiveRecord.
#
# Все публичные методы возвращают одну строку (String) с несколькими строками внутри,
# разделёнными символом перевода строки + "\n" + — так удобно сравнивать с эталоном в тестах
# и выводить через +puts+ в консоли.
#
# == Почему есть QUEST2_MISSION_TITLES
#
# В +db/seeds.rb+ заданы агенты Atlas/Echo/Nova/Viper и 10 миссий с фиксированными названиями.
# В тестах дополнительно подгружаются фикстуры из квеста 1 (лишние агенты и миссии).
# Чтобы ответ совпадал с эталоном, мы считаем «миром квеста 2» только агентов, у которых есть
# хотя бы одна миссия из этого списка, и только такие миссии учитываем в отчётах.
#
# == Синтаксис Ruby, который здесь встречается
#
# * +class << self+ — блок, где методы объявляются «на классе», вызываются так:
#   +Quest2StudentService.all_agents+ (без +.new+).
# * +.freeze+ — константу нельзя случайно переприсвоить; массив строк зафиксирован.
# * +relation.order(:codename)+ — цепочка ActiveRecord: пока не вызовешь +pluck+/+to_a+, SQL может не уйти в БД.
# * +pluck(:column)+ — взять из результата запроса только указанные колонки (массив значений).
# * +includes(:missions)+ — «подгрузить» связанные записи заранее, чтобы не делать N запросов в цикле.
# * +map { |x| ... }+ — превратить каждый элемент коллекции в новое значение; вернуть новый массив.
# * +join("\n")+ — склеить массив строк в одну строку с переводами строк между элементами.
# * +private+ — всё ниже видно только внутри класса, снаружи не вызывают.
# * +"#{a} (#{b})"+ — интерполяция: подставить значения переменных в строку.
# * +&:+ — короткая запись блока: +sort_by(&:name)+ то же, что +sort_by { |x| x.name }+.
#
class Quest2StudentService
  # Полные названия 10 миссий из блока Quest 2 в +db/seeds.rb+ (должны совпадать с сидами).
  # Важно: это массив строк в кавычках, не +%w[Ember Trace]+ — там бы слова разрезались по пробелам.
  QUEST2_MISSION_TITLES = [
    "Ember Trace",
    "Frozen Cipher",
    "Ghost Signal",
    "Glass Horizon",
    "Harbor Shield",
    "Iron Veil",
    "Midnight Relay",
    "Sapphire Run",
    "Silent Echo",
    "Solar Tide"
  ].freeze

  class << self
    # Список кодовых имён всех агентов «квеста 2» — в алфавитном порядке по +codename+.
    # Кто попадает: у кого есть хотя бы одна миссия из +QUEST2_MISSION_TITLES+.
    #
    # @return [String] строки вида "Atlas\nEcho\n..." без лишнего текста в конце
    def all_agents
      quest2_agents_relation.order(:codename).pluck(:codename).join("\n")
    end

    # Все миссии квеста 2 (только из списка названий), отсортированные по +title+ по алфавиту.
    #
    # @return [String] названия миссий, по одному на строку
    def all_missions
      Mission.where(title: QUEST2_MISSION_TITLES).order(:title).pluck(:title).join("\n")
    end

    # Для каждого агента квеста 2 — строка: кодовое имя, двоеточие, список его миссий через запятую.
    # Миссии только из +QUEST2_MISSION_TITLES+, внутри строки — по алфавиту названия.
    # Агенты — по алфавиту +codename+.
    #
    # @return [String] многострочный текст
    def agents_with_missions
      quest2_agents_relation
        .includes(:missions)
        .order(:codename)
        .map { |agent| format_agent_missions_line(agent) }
        .join("\n")
    end

    # То же, что +agents_with_missions+, но:
    # 1) сначала агенты сортируются по убыванию числа учитываемых миссий;
    # 2) при равном числе миссий — по +codename+ по возрастанию;
    # 3) в строке после имени в скобках выводится число миссий: +Echo (4): ...+.
    #
    # @return [String] многострочный текст
    def agents_with_missions_sorted_by_mission_count
      agents = quest2_agents_relation.includes(:missions).to_a
      agents.sort_by! { |agent| [ -quest2_mission_count(agent), agent.codename ] }

      agents.map { |agent| format_agent_missions_line_with_count(agent) }.join("\n")
    end

    # Для каждого агента квеста 2 — навыки из связи +skills+ (через +agent_skills+), по алфавиту имён.
    #
    # @return [String] строки вида "Atlas: Cryptography, Recon"
    def agents_with_skills
      quest2_agents_relation
        .includes(:skills)
        .order(:codename)
        .map { |agent| format_agent_skills_line(agent) }
        .join("\n")
    end

    # Группировка навыков по тому, сколько агентов квеста 2 владеют навыком.
    # Порядок групп: сначала навыки с большим числом агентов (3, потом 2, потом 1).
    # Внутри одной группы навыки по алфавиту +name+; список агентов — по алфавиту +codename+.
    # Учитываются только агенты из +quest2_agent_ids+.
    #
    # @return [String] строки вида "Recon (3): Atlas, Echo, Viper"
    def skills_by_agent_count
      ids = quest2_agent_ids
      skills = Skill.joins(:agents).where(agents: { id: ids }).distinct.includes(:agents).order(:name).to_a

      grouped = skills.group_by { |skill| skill.agents.count { |agent| ids.include?(agent.id) } }

      grouped.keys.sort.reverse.flat_map do |count|
        grouped[count].sort_by(&:name).map do |skill|
          codenames = skill.agents.select { |agent| ids.include?(agent.id) }.sort_by(&:codename).map(&:codename)
          "#{skill.name} (#{count}): #{codenames.join(", ")}"
        end
      end.join("\n")
    end

    private

    # ID всех агентов, у которых в БД есть хотя бы одна миссия с +title+ из +QUEST2_MISSION_TITLES+.
    # +joins(:missions)+ соединяет таблицы +agents+ и +missions+ по внешнему ключу.
    #
    # @return [Array<Integer>]
    def quest2_agent_ids
      Agent.joins(:missions)
        .where(missions: { title: QUEST2_MISSION_TITLES })
        .distinct
        .pluck(:id)
    end

    # Объект-запрос ActiveRecord: все агенты с id из +quest2_agent_ids+ (без повторной сортировки здесь).
    #
    # @return [ActiveRecord::Relation<Agent>]
    def quest2_agents_relation
      Agent.where(id: quest2_agent_ids)
    end

    # Из уже загруженных у агента миссий оставить только те, чьё название в списке квеста 2.
    # Это обычный Ruby +select+ на массиве/коллекции, не SQL +SELECT+.
    #
    # @param agent [Agent]
    # @return [Array<Mission>]
    def quest2_missions_for(agent)
      agent.missions.select { |mission| QUEST2_MISSION_TITLES.include?(mission.title) }
    end

    # Число миссий квеста 2 у данного агента.
    #
    # @param agent [Agent]
    # @return [Integer]
    def quest2_mission_count(agent)
      quest2_missions_for(agent).size
    end

    # Одна строка отчёта: агент и перечисление названий миссий через запятую (по алфавиту).
    def format_agent_missions_line(agent)
      titles = quest2_missions_for(agent).sort_by(&:title).map(&:title)
      "#{agent.codename}: #{titles.join(", ")}"
    end

    # Как +format_agent_missions_line+, но добавлены скобки с количеством миссий после кодового имени.
    def format_agent_missions_line_with_count(agent)
      missions = quest2_missions_for(agent)
      titles = missions.sort_by(&:title).map(&:title)
      "#{agent.codename} (#{missions.size}): #{titles.join(", ")}"
    end

    # Одна строка: агент и навыки через запятую (имена навыков по алфавиту).
    def format_agent_skills_line(agent)
      names = agent.skills.sort_by(&:name).map(&:name)
      "#{agent.codename}: #{names.join(", ")}"
    end
  end
end
