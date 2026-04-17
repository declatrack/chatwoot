class CreateMessageDeliveryLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :message_delivery_logs do |t|
      t.references :message, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.string :channel_type, null: false
      t.string :status, null: false, default: 'pending'
      t.text :error_message
      t.string :external_message_id
      t.jsonb :response_body, default: {}
      t.datetime :attempted_at, null: false

      t.timestamps
    end

    add_index :message_delivery_logs, [:message_id, :status]
    add_index :message_delivery_logs, [:account_id, :created_at]
  end
end
