# Dockerfile robusto para OptimIA - Versión Disruptive SW
FROM ruby:3.4.4-slim as base

# Instalación de dependencias de sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    git \
    curl \
    libvips-dev \
    pkg-config

# Instalar Node.js y Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global yarn

WORKDIR /app

# Instalación de gemas
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copiar el resto de la aplicación
COPY . .

# --- SECCIÓN CRÍTICA PARA OPTIMIA ---
# Capturamos las variables que manda EasyPanel para que el build no falle
ARG SECRET_KEY_BASE
ARG FRONTEND_URL
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
ENV FRONTEND_URL=$FRONTEND_URL
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Precompilación de assets (Aquí es donde nace tu marca OptimIA)
RUN bundle exec rails assets:precompile
# ------------------------------------

# Comando de inicio
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
