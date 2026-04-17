import { computed } from 'vue';
import { useStore } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';

const PERMISSION_DEFAULTS = {
    can_transfer_team: true,
    can_transfer_agent: true,
    can_view_contacts: true,
    can_edit_contacts: true,
    can_view_inbox_tab: true,
    can_view_mentions_tab: true,
    can_view_unattended_tab: true,
    can_view_channels_tab: true,
    can_view_teams_tab: true,
    can_view_only_assigned: false,
    can_view_settings: false,
    can_view_captain: false,
    team_conversation_visibility: 'team_and_unassigned',
};

export function useAgentPermissions() {
    const store = useStore();
    const { isAdmin } = useAdmin();

    const currentUser = computed(() => store.getters.getCurrentUser);

    const agentInStore = computed(() => {
        const agents = store.getters['agents/getAgents'] || [];
        return agents.find(a => a.id === currentUser.value?.id);
    });

    const agentPermissions = computed(() => {
        return agentInStore.value?.agent_permissions || {};
    });

    const hasPermission = key => {
        if (key === 'can_view_only_assigned') {
            if (isAdmin.value) return false;
            const stored = agentPermissions.value;
            if (stored && key in stored) return stored[key];
            return PERMISSION_DEFAULTS[key] ?? false;
        }
        if (key === 'team_conversation_visibility') {
            if (isAdmin.value) return 'all_inbox';
            const stored = agentPermissions.value;
            if (stored && key in stored) return stored[key];
            return PERMISSION_DEFAULTS[key] ?? 'team_and_unassigned';
        }
        if (isAdmin.value) return true;
        const stored = agentPermissions.value;
        if (stored && key in stored) return stored[key];
        return PERMISSION_DEFAULTS[key] ?? true;
    };

    const canTransferTeam = computed(() => hasPermission('can_transfer_team'));
    const canTransferAgent = computed(() => hasPermission('can_transfer_agent'));
    const canViewContacts = computed(() => hasPermission('can_view_contacts'));
    const canEditContacts = computed(() => hasPermission('can_edit_contacts'));
    const canViewInboxTab = computed(() => hasPermission('can_view_inbox_tab'));
    const canViewMentionsTab = computed(() => hasPermission('can_view_mentions_tab'));
    const canViewUnattendedTab = computed(() => hasPermission('can_view_unattended_tab'));
    const canViewChannelsTab = computed(() => hasPermission('can_view_channels_tab'));
    const canViewTeamsTab = computed(() => hasPermission('can_view_teams_tab'));
    const canViewOnlyAssigned = computed(() => hasPermission('can_view_only_assigned'));
    const canViewSettings = computed(() => hasPermission('can_view_settings'));
    const canViewCaptain = computed(() => hasPermission('can_view_captain'));
    const teamConversationVisibility = computed(() => hasPermission('team_conversation_visibility'));

    return {
        hasPermission,
        canTransferTeam,
        canTransferAgent,
        canViewContacts,
        canEditContacts,
        canViewInboxTab,
        canViewMentionsTab,
        canViewUnattendedTab,
        canViewChannelsTab,
        canViewTeamsTab,
        canViewOnlyAssigned,
        canViewSettings,
        canViewCaptain,
        teamConversationVisibility,
    };
}
