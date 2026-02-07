# Dockerfile oficial para Chatwoot - Optimizado para OptimIA
FROM ruby:3.4.4-p34-alpine as base

# Instalación de dependencias de sistema
RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    git \
    nodejs \
    yarn \
    tzdata \
    imagemagick \
    vips-dev

WORKDIR /app

# Instalación de gemas
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copiar el resto de la aplicación
COPY . .

# Precompilación de assets (Aquí es donde se "pega" tu logo de OptimIA)
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Comando de inicio
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
