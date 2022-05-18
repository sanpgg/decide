class BudgetsController < ApplicationController
  include FeatureFlags
  include BudgetsHelper
  feature_flag :budgets

  load_and_authorize_resource
  before_action :set_default_budget_filter, only: :show
  has_filters %w{not_unfeasible feasible unfeasible unselected selected}, only: :show

  respond_to :html, :js

  def show
    raise ActionController::RoutingError, 'Not Found' unless budget_published?(@budget)
  end

  def index

    cu_current_budget = Budget.current.id

    grupos = Budget::Group.where(budget_id: cu_current_budget)

    puts "================================"
    puts "Presupuesto actual: #{cu_current_budget}"

    grupos = grupos.as_json

    grupos.each do |group|

      group['extra'] = ActiveRecord::Base.connection.select_all("SELECT bh.htype, bh.suburb_id, (SELECT name FROM budget_headings WHERE sector = c.sector AND htype = 'sector' AND group_id IN (SELECT id FROM budget_groups WHERE budget_id = #{cu_current_budget}) LIMIT 1) AS sector_header, bh.*
                                                          FROM budget_headings bh
                                                          LEFT JOIN colonia c
                                                            ON c.id = bh.suburb_id
                                                          WHERE bh.group_id = #{group['id']}
                                                          ORDER BY c.sector ASC, bh.name ASC;").to_hash

    end

    @investment_counts = Budget::Investment.where(budget_id: cu_current_budget).distinct.count(:id)
    @finished_budgets = @budgets.finished.order(created_at: :desc)
    @budgets_coordinates = current_budget_map_locations
    @all_investments_map = all_investments_map
    @banners = Banner.in_section('budgets').with_active

    @cards = grupos

  end

end
