import { computed } from 'vue';
import { useStore } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';

/**
 * Composable to determine if the current user can interact with the
 * currently selected conversation (send messages, resolve, change status).
 *
 * Rule: canInteract = isAdmin || (assignee_id === currentUser.id)
 *
 * When canInteract is false the agent can still VIEW the conversation
 * and click "Self Assign" to take ownership.
 */
export function useConversationPermission() {
    const store = useStore();
    const { isAdmin } = useAdmin();

    const currentUser = computed(() => store.getters.getCurrentUser);
    const currentChat = computed(() => store.getters.getSelectedChat);

    const canInteract = computed(() => {
        // Admins can always interact
        if (isAdmin.value) return true;

        // If there is no conversation selected, allow (safe default)
        if (!currentChat.value) return true;

        const assignee = currentChat.value?.meta?.assignee;

        // If no assignee yet, the agent cannot interact (must self-assign first)
        if (!assignee) return false;

        // If the current user IS the assignee, allow interaction
        return assignee.id === currentUser.value?.id;
    });

    return {
        canInteract,
        isAdmin,
    };
}
