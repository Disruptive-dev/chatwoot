# frozen_string_literal: true

class Facebook::MessagingParamsBuilder
  def self.build(base_params)
    new(base_params).build
  end

  def initialize(base_params)
    @params = base_params.deep_dup
  end

  def build
    if human_agent_enabled?
      @params[:messaging_type] = 'MESSAGE_TAG'
      @params[:tag] = 'HUMAN_AGENT'
    else
      @params[:messaging_type] = 'RESPONSE'
      @params.delete(:tag)
    end

    @params
  end

  private

  def human_agent_enabled?
    GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT'].present?
  end
end
