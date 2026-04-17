class SyncWhatsappTemplatesJob < ApplicationJob
  queue_as :default

  def perform(channel_id)
    channel = Channel::Whatsapp.find_by(id: channel_id)
    return unless channel

    channel.provider_service.sync_templates
  end
end
