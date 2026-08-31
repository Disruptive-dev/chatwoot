# frozen_string_literal: true

module Optimia
  module FacebookComments
    class IntentClassifier
      INTENTS = {
        price: /\b(precio|cu[aá]nto\s+sale|valor|costo)\b/i,
        interest: /\b(me\s+interesa|quiero\s+comprar|quiero\s+alquilar)\b/i,
        info: /\b(info|informaci[oó]n|detalles|m[aá]s\s+datos)\b/i,
        location: /\b(ubicaci[oó]n|d[oó]nde\s+queda|zona|barrio)\b/i,
        availability: /\b(disponible|sigue\s+disponible|todav[ií]a\s+est[aá]|se\s+vendi[oó]|alquilado)\b/i,
        visit: /\b(visita|visitarla|visitarlo|verla|verlo|coordinar\s+visita|quiero\s+ver)\b/i,
        handoff: /\b(asesor|hablar\s+con\s+alguien|ll[aá]mame|agente|humano)\b/i,
        personal_data: /\b(\+?\d[\d\s\-]{7,}|[\w.+-]+@[\w-]+\.\w+)\b/
      }.freeze

      def initialize(message)
        @message = message.to_s.strip
      end

      def classify
        return :reaction if emoji_only?
        return :irrelevant if @message.blank?

        INTENTS.each do |intent, pattern|
          return intent if @message.match?(pattern)
        end

        :general
      end

      def confidence
        intent = classify
        return 0.2 if intent == :irrelevant
        return 0.5 if intent == :general

        0.85
      end

      private

      def emoji_only?
        @message.gsub(/\s+/, '').match?(/\A(?:\p{Emoji_Presentation}|\p{Extended_Pictographic})+\z/u)
      end
    end
  end
end
