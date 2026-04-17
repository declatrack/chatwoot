# == Schema Information
#
# Table name: message_delivery_logs
#
#  id                   :bigint           not null, primary key
#  channel_type         :string           not null
#  status               :string           default("pending"), not null
#  error_message        :text
#  external_message_id  :string
#  response_body        :jsonb            default({})
#  attempted_at         :datetime         not null
#  message_id           :bigint           not null
#  account_id           :bigint           not null
#  inbox_id             :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class MessageDeliveryLog < ApplicationRecord
  STATUSES = %w[pending success failed].freeze

  belongs_to :message
  belongs_to :account
  belongs_to :inbox

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :channel_type, presence: true
  validates :attempted_at, presence: true

  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }
  scope :recent, -> { order(attempted_at: :desc) }

  # Convenience factory used by services and model callbacks.
  # Example:
  #   MessageDeliveryLog.log_attempt(message: msg, status: 'failed',
  #                                  error_message: 'Timeout', response_body: {})
  def self.log_attempt(message:, status:, **attrs)
    create!(
      {
        message: message,
        account_id: message.account_id,
        inbox_id: message.inbox_id,
        channel_type: message.inbox.channel_type,
        status: status,
        attempted_at: Time.zone.now
      }.merge(attrs)
    )
  rescue StandardError => e
    Rails.logger.error "[MessageDeliveryLog] Failed to create log for message #{message.id}: #{e.message}"
  end
end
