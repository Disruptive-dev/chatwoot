# frozen_string_literal: true

module Optimia
  module FacebookComments
    class AiReplyGenerator
      def initialize(account:, intent:, property_context:, message:, inbox: nil)
        @account = account
        @intent = intent
        @property_context = property_context
        @message = message.to_s.strip
        @inbox = inbox
      end

      def generate
        return handoff_message if @intent == :handoff

        if Integrations::Optimia::FacebookComments::Feature.ai_reply_enabled_for_account?(@account) && captain_assistant.present?
          captain_reply || template_reply
        else
          template_reply
        end
      end

      private

      def captain_assistant
        @inbox&.captain_assistant
      end

      def captain_reply
        conversation = build_ephemeral_context
        response = Captain::Assistant::AgentRunnerService.new(
          assistant: captain_assistant,
          conversation: conversation
        ).generate_response(message_history: captain_message_history)

        content = response['response'].to_s.strip
        return nil if content.blank? || content == 'conversation_handoff'

        content
      rescue StandardError => e
        Rails.logger.warn({ event: 'optimia_fb_comment_captain_fallback', error_class: e.class.name }.to_json)
        nil
      end

      def build_ephemeral_context
        Conversation.new(
          account: @account,
          inbox: @inbox,
          additional_attributes: {
            'optimia_facebook_comment' => true,
            'property_context' => @property_context.to_h
          }
        )
      end

      def captain_message_history
        [
          { role: 'system', content: system_prompt },
          { role: 'user', content: @message }
        ]
      end

      def system_prompt
        facts = @property_context.known_facts.presence || {}
        <<~PROMPT.squish
          Respond in Spanish for a Facebook Page comment about real estate.
          Structure: ANSWER the question, provide VALUE from known facts only, end with a short MICRO_CTA.
          Do NOT ask for the user's name unless they volunteered contact details.
          Do NOT invent price, location, availability, bedrooms, or expenses.
          Known facts (official only): #{facts.to_json}
          Property ID: #{@property_context.property_id || 'unknown'}
          Intent: #{@intent}
        PROMPT
      end

      def template_reply
        case @intent
        when :price
          price_reply
        when :interest
          interest_reply
        when :info
          info_reply
        when :location
          location_reply
        when :availability
          availability_reply
        when :visit
          visit_reply
        when :handoff
          handoff_message
        when :personal_data
          private_ack_reply
        else
          general_reply
        end
      end

      def price_reply
        price = @property_context.fact('price')
        if price.present?
          "El precio publicado es #{price}. ¿Te gustaría que te enviemos más detalles por mensaje privado?"
        else
          'Con gusto te ayudamos con el precio de esta propiedad. Escríbenos por mensaje privado y te respondemos con la información oficial.'
        end
      end

      def interest_reply
        '¡Gracias por tu interés! Podemos coordinar los próximos pasos para esta propiedad. ¿Preferís que te contactemos por mensaje privado?'
      end

      def info_reply
        if @property_context.present?
          'Tenemos información oficial sobre esta publicación. ¿Qué aspecto te gustaría conocer: precio, ubicación o disponibilidad?'
        else
          'Con gusto te ayudamos con esta publicación. Escribinos por mensaje privado y te compartimos los detalles oficiales.'
        end
      end

      def location_reply
        location = @property_context.fact('location') || @property_context.fact('address')
        if location.present?
          "La ubicación publicada es #{location}. ¿Querés que te enviemos el plano o más fotos por mensaje privado?"
        else
          'Podemos confirmarte la ubicación oficial de esta propiedad por mensaje privado. ¡Escribinos!'
        end
      end

      def availability_reply
        availability = @property_context.fact('availability') || @property_context.fact('status')
        if availability.present?
          "Según nuestros registros, el estado es: #{availability}. ¿Te gustaría agendar una visita?"
        else
          'Podemos confirmarte la disponibilidad actual por mensaje privado. ¡Escribinos y te respondemos!'
        end
      end

      def visit_reply
        'Para coordinar una visita, te escribimos por mensaje privado y un asesor te contactará a la brevedad.'
      end

      def handoff_message
        'Un asesor se pondrá en contacto contigo a la brevedad. ¡Gracias por escribirnos!'
      end

      def private_ack_reply
        'Recibimos tu mensaje. Un asesor te contactará por mensaje privado para continuar de forma segura.'
      end

      def general_reply
        'Gracias por tu consulta sobre esta publicación. ¿En qué podemos ayudarte: precio, ubicación o disponibilidad?'
      end
    end
  end
end
