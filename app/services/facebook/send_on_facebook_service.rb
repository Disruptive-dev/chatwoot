class Facebook::SendOnFacebookService < Base::SendOnChannelService
  include Facebook::GraphApiSupport

  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    send_message_to_facebook fb_text_message_params if message.content.present?

    if message.attachments.present?
      message.attachments.each do |attachment|
        send_message_to_facebook fb_attachment_message_params(attachment)
      end
    end
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    log_send_failure(graph_error_metadata(e).merge(error_class: e.class.name, error_message: e.message))
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def send_message_to_facebook(delivery_params)
    log_event('facebook_message_send_started', send_log_payload(delivery_params))

    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      error_metadata = extract_response_error(parsed_result)
      log_send_failure(error_metadata, delivery_params)
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_result)).perform
      return
    end

    return if parsed_result['message_id'].blank?

    message.update!(source_id: parsed_result['message_id'])
    Messages::StatusUpdateService.new(message, 'sent').perform
    log_event('facebook_message_send_succeeded', send_log_payload(delivery_params))
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    log_send_failure({ error_class: 'JSON::ParserError', error_message: 'invalid_json_response' }, delivery_params)
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    nil
  rescue Net::OpenTimeout
    log_send_failure({ error_class: 'Net::OpenTimeout', error_message: 'timeout' }, delivery_params)
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
    nil
  end

  def fb_text_message_params
    Facebook::MessagingParamsBuilder.build(
      recipient: { id: contact.get_source_id(inbox.id) },
      message: fb_text_message_payload
    )
  end

  def fb_text_message_payload
    if message.content_type == 'input_select' && message.content_attributes['items'].any?
      {
        text: message.content,
        quick_replies: message.content_attributes['items'].map do |item|
          {
            content_type: 'text',
            payload: item['title'],
            title: item['title']
          }
        end
      }
    else
      { text: message.outgoing_content }
    end
  end

  def external_error(response)
    error_message = response['error']['message']
    error_code = response['error']['code']

    "#{error_code} - #{error_message}"
  end

  def fb_attachment_message_params(attachment)
    Facebook::MessagingParamsBuilder.build(
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    )
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def handle_facebook_error(exception)
    return unless exception.to_s.include?('The session has been invalidated') || exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end

  def send_log_payload(delivery_params = {})
    recipient_id = delivery_params.dig(:recipient, :id) || contact.get_source_id(inbox.id)
    {
      account_id: message.account_id,
      inbox_id: inbox.id,
      page_id: channel.page_id,
      conversation_id: conversation.id,
      message_id: message.id,
      recipient_psid_masked: mask_psid(recipient_id),
      messaging_type: delivery_params[:messaging_type],
      payload_fields: delivery_params.keys.map(&:to_s),
      graph_api_version: api_version
    }.compact
  end

  def log_send_failure(metadata, delivery_params = {})
    log_event('facebook_message_send_failed', send_log_payload(delivery_params).merge(metadata))
  end

  def extract_response_error(parsed_result)
    error = parsed_result['error'] || {}
    {
      error_type: error['type'],
      error_code: error['code'],
      error_subcode: error['error_subcode'],
      fbtrace_id: error['fbtrace_id'],
      error_message: error['message']
    }.compact
  end
end
