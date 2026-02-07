# Dockerfile robusto para OptimIA - Versión Disruptive SW
FROM ruby:3.4.4-slim as base

# Instalación de dependencias de sistema (Debian style)
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    git \
    curl \
    libvips-dev \
    pkg-config

# Instalar Node.js y Yarn (fundamentales para los logos y el frontend)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global yarn

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
