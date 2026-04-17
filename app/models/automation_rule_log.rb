class AutomationRuleLog < ApplicationRecord
  belongs_to :automation_rule
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true

  enum status: { processing: 0, success: 1, failed: 2, ignored: 3 }

  def self.create_log(rule, account, conversation, options = {})
    log = create!(
      automation_rule: rule,
      account: account,
      conversation: conversation,
      inbox: conversation&.inbox,
      contact: conversation&.contact,
      automation_rule_name: rule.name,
      event_name: rule.event_name,
      status: :processing,
      execution_start: Time.current
    )
    yield log if block_given?
    log.update(execution_end: Time.current) if log.execution_end.blank?
    log
  rescue StandardError => e
    Rails.logger.error "Error in AutomationRuleLog.create_log: #{e.message}"
    yield nil if block_given?
  end
end
