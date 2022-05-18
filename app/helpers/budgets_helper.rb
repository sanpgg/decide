module BudgetsHelper

  def show_links_to_budget_investments(budget)
    ['balloting', 'reviewing_ballots', 'finished'].include? budget.phase
  end

  def heading_name_and_price_html(heading, budget)
    if heading.name.include?("Revoluicion")
      heading.name
      heading.name.sub! 'Revoluicion', 'Revolución'
    end
    content_tag :div do
      concat(heading.name + ' ')
      concat(content_tag(:span, budget.formatted_heading_price(heading)))
    end
  end

  def heading_name_and_price_html_from_js(heading)

    if heading['name'].include?("Revoluicion")
      heading['name']
      heading['name'].sub! 'Revoluicion', 'Revolución'
    end
    content_tag :div do
      concat(heading['name'] + ' ')
      concat(content_tag(:span, ActionController::Base.helpers.number_to_currency(heading['price'],
                                                      separator: '.',
                                                      delimiter: ",",
                                                      format: "%u %n",
                                                      unit: '$')))
    end
  end

  def csv_params
    csv_params = params.clone.merge(format: :csv).symbolize_keys
    csv_params.delete(:page)
    csv_params
  end

  def budget_phases_select_options
    Budget::Phase::PHASE_KINDS.map { |ph| [ t("budgets.phase.#{ph}"), ph ] }
  end

  def budget_currency_symbol_select_options
    #Budget::CURRENCY_SYMBOLS.map { |cs| [ cs, cs ] }
    f = Budget::CURRENCY_SYMBOLS.map { |cs| [ cs, cs ] }

    puts f.inspect

    return f
  end

  def namespaced_budget_investment_path(investment, options = {})
    case namespace
    when "management"
      management_budget_investment_path(investment.budget, investment, options)
    else
      budget_investment_path(investment.budget, investment, options)
    end
  end

  def namespaced_budget_investment_vote_path(investment, options = {})
    case namespace
    when "management"
      vote_management_budget_investment_path(investment.budget, investment, options)
    else
      vote_budget_investment_path(investment.budget, investment, options)
    end
  end

  def display_budget_countdown?(budget)
    budget.balloting?
  end

  def css_for_ballot_heading(heading)
    return '' if current_ballot.blank?
    current_ballot.has_lines_in_heading?(heading) ? 'is-active' : ''
  end

  def current_ballot
    Budget::Ballot.where(user: current_user, budget: @budget).first
  end

  def budget_headings_select_type_options
    
    f = Budget::HeadingType::HEADING_KINDS.map { |ph| [ t("budgets.heading_types.#{ph}"), ph ] }

    return f
  end

  def budget_headings_select_suburbs_options(budget)
    f = Budget::Heading.joins("INNER JOIN budget_groups
                                  ON budget_groups.budget_id = #{budget.id}
                                  AND budget_groups.id = budget_headings.group_id
                                WHERE budget_headings.sector IS NOT NULL
                                AND budget_headings.htype = 'sector';").map { |h| [h.name, h.id] }

    col = Colonium.order('junta_nom ASC').map {|c| [c.junta_nom, c.id]}

    col.insert(0, ["No vincular", 0])

    return col
  end

  def budget_headings_select_sector_options(budget)

    sectors = Colonium.select('sector').group(:sector).order('sector ASC').map {|c| [c.sector, c.sector]}

    sectors.insert(0, ["No vincular", 0])

    return sectors
  end

  def investment_tags_select_options(budget)
    Budget::Investment.by_budget(budget).tags_on(:valuation).order(:name).select(:name).distinct
  end

  def budget_published?(budget)
    !budget.drafting? || current_user&.administrator?
  end

  def current_budget_map_locations
    return unless current_budget.present?
    if current_budget.valuating_or_later?
      if current_budget.finished?
        investments = current_budget.investments.winners
      else
        investments = current_budget.investments.selected
      end
    else
      investments = current_budget.investments
    end

    investments = current_budget.investments
    MapLocation.where(investment_id: investments).map { |l| l.json_data }
  end

  def all_investments_map
    investments = current_budget.investments
    MapLocation.where(investment_id: investments).map { |l| l.json_data }
  end

  def display_calculate_winners_button?(budget)
    budget.balloting_or_later?
  end

  def calculate_winners_admin_budget_path(budget)
    admin_budget_budget_investments_path(budget_id: budget.id)+'/calculate_winners'      
  end

  def calculate_winner_button_text(budget)
    if budget.investments.winners.empty?
      t("admin.budgets.winners.calculate")
    else
      t("admin.budgets.winners.recalculate")
    end
  end
end
