json.payload do
  json.array! @logs do |log|
    json.id log.id
    json.automation_rule_id log.automation_rule_id
    json.automation_rule_name log.automation_rule_name
    json.event_name log.event_name
    json.status log.status
    json.error_message log.error_message
    json.actions_data log.actions_data
    json.execution_start log.execution_start.to_i
    json.execution_end log.execution_end.to_i
    json.created_at log.created_at.to_i
    if log.conversation
      json.conversation do
        json.id log.conversation.id
        json.display_id log.conversation.display_id
      end
    end
    if log.contact
      json.contact do
        json.id log.contact.id
        json.name log.contact.name
      end
    end
    if log.inbox
      json.inbox do
        json.id log.inbox.id
        json.name log.inbox.name
      end
    end
  end
end
