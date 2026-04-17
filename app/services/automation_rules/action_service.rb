class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation, options = {})
    super(conversation)
    @rule = rule
    @account = account
    @log = options[:log]
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation.reload
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
        track_action(action, :success)
      rescue StandardError => e
        track_action(action, :failed, e.message)
        @log.update(status: :failed, error_message: e.message) if @log
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def track_action(action, status, error = nil)
    return unless @log

    @log.actions_data << {
      action_name: action[:action_name],
      action_params: action[:action_params],
      status: status,
      error: error,
      executed_at: Time.current
    }
    @log.save!
  rescue StandardError => e
    Rails.logger.error "Error tracking action in AutomationRules::ActionService: #{e.message}"
  end

  private

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    return unless @rule.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end

  def send_whatsapp_template(params)
    inbox = @conversation.inbox
    return unless inbox.whatsapp? || (inbox.twilio? && inbox.channel.whatsapp?)

    template_params = params[0].with_indifferent_access
    
    template = inbox.channel.message_templates.find do |t| 
      t['name'] == template_params[:template_name] && t['language'] == template_params[:language]
    end

    resolver = Whatsapp::TemplateVariableResolverService.new(
      template: template,
      contact: @conversation.contact,
      params: { variables: template_params[:variables] }
    )
    resolved_params = resolver.resolve

    # Automations pass variables as a flat hash, but the message needs them in processed_params format
    # The resolver handles the distribution if we pass them correctly.
    # Actually, in Automation context, the previous code was manually distributing:
    header_vars = resolved_params[:header_text]
    body_vars = resolved_params[:body]

    message_content = "Automation: Sending WhatsApp Template #{template_params[:template_name]}"
    if template
      body_comp = template['components'].find { |c| c['type'] == 'BODY' }
      if body_comp && body_comp['text'].present?
        message_content = body_comp['text'].dup
        body_keys = body_comp['text'].scan(/{{([^}]+)}}/).flatten
        body_keys.each do |key|
          val = body_vars[key.to_sym] || body_vars[key.to_s] || '-'
          message_content.gsub!("{{#{key}}}", val.to_s)
        end
      end
    end

    @conversation.messages.create!(
      content: message_content,
      account_id: @account.id,
      inbox_id: inbox.id,
      message_type: :template,
      status: :sent,
      content_type: :text,
      content_attributes: {
        automation_rule_id: @rule.id
      },
      additional_attributes: {
        template_params: {
          name: template_params[:template_name],
          language: template_params[:language],
          processed_params: {
            header_text: header_vars.presence,
            body: body_vars.presence
          }.compact
        }
      }
    )
  end
end
