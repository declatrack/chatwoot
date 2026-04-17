#######################################
# To create an external channel reply service
# - Inherit this as the base class.
# - Implement `channel_class` method in your child class.
# - Implement `perform_reply` method in your child class.
# - Implement additional custom logic for your `perform_reply` method.
# - When required override the validation_methods.
# - Use Childclass.new.perform.
######################################
class Base::SendOnChannelService
  pattr_initialize [:message!]

  def perform
    validate_target_channel
    return unless outgoing_message?
    return if invalid_message?

    perform_and_log_reply
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :contact_inbox, :inbox, to: :conversation
  delegate :channel, to: :inbox

  def channel_class
    raise 'Overwrite this method in child class'
  end

  def perform_reply
    raise 'Overwrite this method in child class'
  end

  def outgoing_message_originated_from_channel?
    # TODO: we need to refactor this logic as more integrations comes by
    # chatwoot messages won't have source id at the moment
    # TODO: migrate source_ids to external_source_ids and check the source id relevant to specific channel
    message.source_id.present?
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def invalid_message?
    # private notes aren't send to the channels
    # we should also avoid the case of message loops, when outgoing messages are created from channel
    message.private? || outgoing_message_originated_from_channel?
  end

  def validate_target_channel
    raise 'Invalid channel service was called' if inbox.channel.class != channel_class
  end

  def perform_and_log_reply
    source_id_before = message.source_id
    perform_reply
    # Capture the external message ID if the channel set it during perform_reply
    external_id = message.source_id != source_id_before ? message.source_id : nil
    log_delivery(status: 'success', external_message_id: external_id)
  rescue StandardError => e
    log_delivery(status: 'failed', error_message: e.message)
    raise
  end

  def log_delivery(status:, **attrs)
    return unless message.outgoing? || message.template?

    MessageDeliveryLog.log_attempt(
      message: message,
      status: status,
      **attrs
    )
  rescue StandardError => e
    Rails.logger.error "[SendOnChannelService] Could not create delivery log: #{e.message}"
  end
end
