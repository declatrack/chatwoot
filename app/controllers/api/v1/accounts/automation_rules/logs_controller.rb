class Api::V1::Accounts::AutomationRules::LogsController < Api::V1::Accounts::BaseController
  before_action :fetch_automation_rule

  def index
    @logs = @automation_rule.automation_rule_logs.order(created_at: :desc).limit(100)
  end

  private

  def fetch_automation_rule
    @automation_rule = Current.account.automation_rules.find(params[:automation_rule_id])
  end
end
