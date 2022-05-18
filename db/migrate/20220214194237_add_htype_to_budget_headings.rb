class AddHtypeToBudgetHeadings < ActiveRecord::Migration
  def change
    add_column :budget_headings, :htype, :text
  end
end
