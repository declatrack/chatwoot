import { MESSAGE_TYPE } from 'shared/constants/messages';
import { applyPageFilters, applyRoleFilter, sortComparator } from './helpers';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import { matchesFilters } from './helpers/filterHelpers';
import {
  getUserPermissions,
  getUserRole,
} from '../../../helper/permissionsHelper';
import camelcaseKeys from 'camelcase-keys';

export const getSelectedChatConversation = ({
  allConversations,
  selectedChatId,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChatId);

const applyTeamFilter = (conversation, myTeams, isAdmin, visibility) => {
  if (isAdmin || visibility === 'all_inbox') return true;
  const conversationTeamId = conversation.meta?.team?.id;
  if (!conversationTeamId) return visibility !== 'team_only';
  return myTeams.some(t => t.id === conversationTeamId);
};

const getters = {
  getAllConversations: ({ allConversations, chatSortFilter: sortKey }) => {
    return allConversations.sort((a, b) => sortComparator(a, b, sortKey));
  },
  getFilteredConversations: (
    { allConversations, chatSortFilter, appliedFilters },
    _,
    __,
    rootGetters
  ) => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);

    return allConversations
      .filter(conversation => {
        const matchesFilterResult = matchesFilters(
          conversation,
          appliedFilters
        );
        const allowedForRole = applyRoleFilter(
          conversation,
          userRole,
          permissions,
          currentUserId
        );
        const isAdmin = userRole === 'administrator';
        const myTeams = rootGetters['teams/getMyTeams'] || [];
        const agentPermissions = rootGetters['agents/getAgents']?.find(a => a.id === currentUserId)?.agent_permissions || {};
        const visibility = agentPermissions.team_conversation_visibility ?? 'team_and_unassigned';
        const allowedByTeam = applyTeamFilter(conversation, myTeams, isAdmin, visibility);

        return matchesFilterResult && allowedForRole && allowedByTeam;
      })
      .sort((a, b) => sortComparator(a, b, chatSortFilter));
  },
  getSelectedChat: ({ selectedChatId, allConversations }) => {
    const selectedChat = allConversations.find(
      conversation => conversation.id === selectedChatId
    );
    return selectedChat || {};
  },
  getSelectedChatAttachments: ({ selectedChatId, attachments }) => {
    return attachments[selectedChatId] || [];
  },
  getChatListFilters: ({ conversationFilters }) => conversationFilters,
  getLastEmailInSelectedChat: (stage, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    const { messages = [] } = selectedChat;
    const lastEmail = [...messages].reverse().find(message => {
      const { message_type: messageType } = message;
      if (message.private) return false;

      return [MESSAGE_TYPE.OUTGOING, MESSAGE_TYPE.INCOMING].includes(
        messageType
      );
    });

    return lastEmail;
  },
  getMineChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserID = rootGetters.getCurrentUser?.id;
    const currentAccountId = rootGetters.getCurrentAccountId;
    const userRole = getUserRole(rootGetters.getCurrentUser, currentAccountId);
    const isAdmin = userRole === 'administrator';
    const myTeams = rootGetters['teams/getMyTeams'] || [];
    const agentPermissions = rootGetters['agents/getAgents']?.find(a => a.id === currentUserID)?.agent_permissions || {};
    const visibility = agentPermissions.team_conversation_visibility ?? 'team_and_unassigned';

    return _state.allConversations.filter(conversation => {
      const { assignee } = conversation.meta;
      const isAssignedToMe = assignee && assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const allowedByTeam = applyTeamFilter(conversation, myTeams, isAdmin, visibility);
      const isChatMine = isAssignedToMe && shouldFilter && allowedByTeam;

      return isChatMine;
    });
  },
  getAppliedConversationFiltersV2: _state => {
    // TODO: Replace existing one with V2 after migrating the filters to use camelcase
    return _state.appliedFilters.map(camelcaseKeys);
  },
  getAppliedConversationFilters: _state => {
    return _state.appliedFilters;
  },
  getAppliedConversationFiltersQuery: _state => {
    const hasAppliedFilters = _state.appliedFilters.length !== 0;
    return hasAppliedFilters ? filterQueryGenerator(_state.appliedFilters) : [];
  },
  getUnAssignedChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserId = rootGetters.getCurrentUser?.id;
    const currentAccountId = rootGetters.getCurrentAccountId;
    const userRole = getUserRole(rootGetters.getCurrentUser, currentAccountId);
    const isAdmin = userRole === 'administrator';
    const myTeams = rootGetters['teams/getMyTeams'] || [];
    const agentPermissions = rootGetters['agents/getAgents']?.find(a => a.id === currentUserId)?.agent_permissions || {};
    const visibility = agentPermissions.team_conversation_visibility ?? 'team_and_unassigned';

    return _state.allConversations.filter(conversation => {
      const isUnAssigned = !conversation.meta.assignee;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const allowedByTeam = applyTeamFilter(conversation, myTeams, isAdmin, visibility);
      return isUnAssigned && shouldFilter && allowedByTeam;
    });
  },
  getAllStatusChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);

    return _state.allConversations.filter(conversation => {
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const allowedForRole = applyRoleFilter(
        conversation,
        userRole,
        permissions,
        currentUserId
      );
      const isAdmin = userRole === 'administrator';
      const myTeams = rootGetters['teams/getMyTeams'] || [];
      const agentPermissions = rootGetters['agents/getAgents']?.find(a => a.id === currentUserId)?.agent_permissions || {};
      const visibility = agentPermissions.team_conversation_visibility ?? 'team_and_unassigned';
      const allowedByTeam = applyTeamFilter(conversation, myTeams, isAdmin, visibility);

      return shouldFilter && allowedForRole && allowedByTeam;
    });
  },
  getChatListLoadingStatus: ({ listLoadingStatus }) => listLoadingStatus,
  getAllMessagesLoaded(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return !chat || chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = getSelectedChatConversation(_state);
    if (!chat) return [];
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        chatMessage.message_type === 0 &&
        chatMessage.private !== true
    ).length;
  },
  getChatStatusFilter: ({ chatStatusFilter }) => chatStatusFilter,
  getChatSortFilter: ({ chatSortFilter }) => chatSortFilter,
  getSelectedInbox: ({ currentInbox }) => currentInbox,
  getConversationById: _state => conversationId => {
    return _state.allConversations.find(
      value => value.id === Number(conversationId)
    );
  },
  getConversationParticipants: _state => {
    return _state.conversationParticipants;
  },
  getConversationLastSeen: _state => {
    return _state.conversationLastSeen;
  },

  getContextMenuChatId: _state => {
    return _state.contextMenuChatId;
  },

  getCopilotAssistant: _state => {
    return _state.copilotAssistant;
  },
};

export default getters;
