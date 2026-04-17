class CreateAutomationRuleLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :automation_rule_logs do |t|
      t.references :automation_rule, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :inbox, foreign_key: true
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.string :automation_rule_name
      t.string :event_name, null: false
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.jsonb :actions_data, default: [], null: false
      t.datetime :execution_start
      t.datetime :execution_end

      t.timestamps
    end
    add_index :automation_rule_logs, :status
    add_index :automation_rule_logs, :created_at
  end
end
