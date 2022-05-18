class RemoveFieldnameFromBudgetHeadings < ActiveRecord::Migration
  def change
    remove_column :budget_headings, :type, :text
  end
end
