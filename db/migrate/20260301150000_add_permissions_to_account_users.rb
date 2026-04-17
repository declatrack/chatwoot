class AddPermissionsToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:account_users, :permissions)
      add_column :account_users, :permissions, :jsonb, default: {}, null: false
    end
  end
end
