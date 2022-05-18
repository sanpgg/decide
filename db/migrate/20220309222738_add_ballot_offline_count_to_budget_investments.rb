class AddBallotOfflineCountToBudgetInvestments < ActiveRecord::Migration
  def change
    add_column :budget_investments, :ballot_offline_count, :integer, default: 0
  end
end
