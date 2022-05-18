class RenameUserNameColumn < ActiveRecord::Migration
  def change
    rename_column :users, :name, :born_names
  end
end
