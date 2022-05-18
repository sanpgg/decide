class AddDescriptionToBudgetHeadings < ActiveRecord::Migration
  def change
    add_column :budget_headings, :description, :text
  end
end
