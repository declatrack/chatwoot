json.extract! @message,
              :id, :content, :inbox_id, :conversation_id, :message_type,
              :content_type, :status, :private, :source_id,
              :content_attributes, :additional_attributes

json.created_at @message.created_at.to_i
json.channel_type @message.inbox.channel_type

json.sender @message.sender.push_event_data if @message.sender
json.attachments @message.attachments.map(&:push_event_data) if @message.attachments.present?

json.delivery_logs @delivery_logs do |log|
  json.id log.id
  json.status log.status
  json.channel_type log.channel_type
  json.external_message_id log.external_message_id
  json.error_message log.error_message
  json.response_body log.response_body
  json.attempted_at log.attempted_at.iso8601
  json.created_at log.created_at.iso8601
end
