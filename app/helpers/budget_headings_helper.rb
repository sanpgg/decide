module BudgetHeadingsHelper

  def budget_heading_select_options_all(budget)
   budget.headings.order_by_group_name.map do |heading|
     [heading.name_scoped_by_group, heading.id]
   end
  end

  def get_coloniums
    Colonium.order('sector ASC, junta_nom ASC').map do |colonia|
      ["#{colonia.sector}: #{colonia.junta_nom}", colonia.id]
    end
  end

  def budget_heading_select_options(budget)

    if current_user.colonium

      sector = current_user.colonium.first.sector
      col_id = current_user.colonium.first.id

      cu_current_budget = Budget.current.id

      suburbs = budget.headings.order_by_group_name_condition(sector, col_id).map { |heading| [heading.name_scoped_by_group, heading.id] }

      return suburbs;

    else

      budget.headings.order_by_group_name.map { |heading| [heading.name_scoped_by_group, heading.id] }

    end

  end

  def budget_heading_for_investments_select_options(budget)

    if current_user.colonium

      sector = current_user.colonium.first.sector
      col_id = current_user.colonium.first.id

      cu_current_budget = Budget.current.id

      # Obtener propuestas hechas por el usuario
      investments = Budget::Investment.where(budget_id: Budget.current.id, author_id: current_user.id)

      # Filtrar eliminando las partidas que ya tengan propuesta
      suburbs = budget.headings.order_by_group_name_condition(sector, col_id).map do |heading|
        [heading.name_scoped_by_group, heading.id] if !investments.any?{|element| element.heading_id == heading.id}
      end

      suburbs.reject! { |c| c.blank? }

      return suburbs;

    else

      budget.headings.order_by_group_name.map { |heading| [heading.name_scoped_by_group, heading.id] }

    end

  end

  def budget_heading_descriptions(budget)
    budget.headings.order_by_group_name_no_null_description.map do |heading|
      [heading.description, heading.id]
    end
  end

  def heading_link(assigned_heading = nil, budget = nil)
    return nil unless assigned_heading && budget
    heading_path = budget_investments_path(budget, heading_id: assigned_heading.try(:id))
    link_to(assigned_heading.name, heading_path)
  end
end
