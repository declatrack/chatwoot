class AddEnableAutoSignatureToInboxes < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:inboxes, :enable_auto_signature)
      add_column :inboxes, :enable_auto_signature, :boolean, default: false, null: false
    end
  end
end
