class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_role == 'administrator'

    accessible_conversations
  end

  private

  def accessible_conversations
    inbox_filtered = conversations.where(inbox: user.inboxes.where(account_id: account.id))
    filter_by_team_membership(inbox_filtered)
  end

  def filter_by_team_membership(convos)
    user_team_ids = TeamMember.where(user_id: user.id).joins(:team).where(teams: { account_id: account.id }).pluck(:team_id)
    visibility = account_user&.has_permission?('team_conversation_visibility') || 'team_and_unassigned'

    case visibility
    when 'all_inbox'
      convos
    when 'team_only'
      user_team_ids.any? ? convos.where(team_id: user_team_ids) : convos.none
    else # team_and_unassigned (default)
      if user_team_ids.any?
        convos.where('conversations.team_id IS NULL OR conversations.team_id IN (?)', user_team_ids)
      else
        convos.where(team_id: nil)
      end
    end
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
