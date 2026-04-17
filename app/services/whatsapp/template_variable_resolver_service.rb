class Whatsapp::TemplateVariableResolverService
  def initialize(template:, contact:, params: {})
    @template = template
    @contact = contact
    @params = params.with_indifferent_access
  end

  def resolve
    # Support both flat 'variables' (from Automations) and grouped 'header_text'/'body' (from API/New UI)
    @variables_pool = @params[:variables] || {}
    
    @resolved_params = {
      header_text: resolve_group(@params[:header_text], 'HEADER'),
      body: resolve_group(@params[:body], 'BODY'),
      buttons: resolve_buttons(@params[:buttons])
    }.compact
  end

  def rendered_content
    @resolved_params ||= resolve
    body_comp = @template['components']&.find { |c| c['type'] == 'BODY' }
    return "Template: #{@template['name']}" if body_comp.blank? || body_comp['text'].blank?

    content = body_comp['text'].dup
    (@resolved_params[:body] || {}).each do |key, value|
      content.gsub!("{{#{key}}}", value.to_s)
    end
    content
  end

  private

  def resolve_group(provided_values, type)
    component = @template['components']&.find { |c| c['type'] == type }
    return nil if component.blank? || component['text'].blank?

    placeholders = component['text'].scan(/{{([^}]+)}}/).flatten
    return nil if placeholders.empty?

    # Initialize result with provided values, or look into the flat variables pool
    result = (provided_values || {}).dup
    
    placeholders.each do |key|
      # Look for value in: 1. Grouped params, 2. Flat variables pool
      val = result[key] || @variables_pool[key]
      
      if val.blank?
        result[key] = fetch_variable_value(key)
      elsif val.to_s.start_with?('{{') && val.to_s.end_with?('}}')
        # Support automation-style explicit placeholders: { "1": "{{first_name}}" }
        variable_name = val.to_s.gsub(/[{}]/, '')
        result[key] = fetch_variable_value(variable_name)
      else
        result[key] = val
      end
      
      # Final fallback
      result[key] = '-' if result[key].blank?
    end
    result
  end

  def resolve_buttons(buttons)
    return nil if buttons.blank?

    buttons.map do |button|
      resolved_button = button.dup
      if resolved_button[:parameter].blank?
        # Note: Button auto-fill is less common but we can support it if a variable is passed
        # Currently, buttons usually expect a specific value like an OTP or ID.
      elsif resolved_button[:parameter].to_s.start_with?('{{') && resolved_button[:parameter].to_s.end_with?('}}')
        variable_name = resolved_button[:parameter].to_s.gsub(/[{}]/, '')
        resolved_button[:parameter] = fetch_variable_value(variable_name)
      end
      resolved_button
    end
  end

  def fetch_variable_value(name)
    value = case name.downcase
            when 'first_name' then @contact.name&.split(' ')&.first
            when 'last_name' then @contact.name&.split(' ')&.drop(1)&.join(' ')
            when 'full_name', 'name' then @contact.name
            when 'email' then @contact.email
            when 'phone', 'phone_number' then @contact.phone_number
            when 'city' then @contact.additional_attributes['city'] || @contact.custom_attributes['city']
            when 'country' then @contact.additional_attributes['country_code'] || @contact.additional_attributes['country'] || @contact.custom_attributes['country']
            when 'company_name', 'company' then @contact.additional_attributes['company_name'] || @contact.custom_attributes['company_name']
            when 'bio', 'description' then @contact.additional_attributes['description'] || @contact.custom_attributes['bio'] || @contact.description
            else
              resolve_custom_variable(name)
            end
    
    format_value(value)
  end

  def resolve_custom_variable(name)
    if name.start_with?('ca_')
      attr_key = name.sub('ca_', '')
      @contact.custom_attributes[attr_key] || @contact.additional_attributes[attr_key] || ''
    else
      # Try exact match in custom attributes if not matched by standard rules
      @contact.custom_attributes[name] || ''
    end
  end

  def format_value(value)
    return '-' if value.blank?
    
    val_str = value.to_s
    # Regex to detect ISO Date (YYYY-MM-DD...)
    iso_date_regex = /^(\d{4})-(\d{2})-(\d{2})(T\d{2}:\d{2}:\d{2}.*)?$/
    match = val_str.match(iso_date_regex)
    
    if match
      year, month, day = match[1], match[2], match[3]
      "#{day}/#{month}/#{year}"
    else
      val_str
    end
  end
end
