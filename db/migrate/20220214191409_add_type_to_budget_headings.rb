class AddTypeToBudgetHeadings < ActiveRecord::Migration
  def change
    add_column :budget_headings, :type, :text
  end
end
