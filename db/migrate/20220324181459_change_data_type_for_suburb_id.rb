class ChangeDataTypeForSuburbId < ActiveRecord::Migration
  def change
    change_column(:budget_headings, :suburb_id, 'integer USING CAST(suburb_id AS integer)')
  end
end