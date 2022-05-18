class AddCurpInformationToUser < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :paternal_last_name, :string
    add_column :users, :maternal_last_name, :string
    add_column :users, :birthplace, :string
    add_column :users, :curp, :string

    add_index :users, :curp
  end
end
