# Dockerfile PRO para OptimIA - Disruptive SW Standard
FROM ruby:3.4.4-slim as base

# Instalación de dependencias de sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    git \
    curl \
    libvips-dev \
    pkg-config

# Instalamos Node.js 24 (el que pide tu proyecto) y pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global pnpm

WORKDIR /app

# Instalación de gemas (Esto vuela porque está en caché)
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Dependencias de diseño
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# Copiar el resto de la aplicación
COPY . .

# --- SECCIÓN DE ALTO RENDIMIENTO E IDENTIDAD OPTIMIA ---
ARG SECRET_KEY_BASE
ARG FRONTEND_URL
# Inyectamos el nombre de marca directamente en el proceso de horneado
ARG INSTALLATION_NAME="OptimIA"
ARG BRAND_NAME="OptimIA"

ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
ENV FRONTEND_URL=$FRONTEND_URL
ENV INSTALLATION_NAME=$INSTALLATION_NAME
ENV BRAND_NAME=$BRAND_NAME
ENV RAILS_ENV=production
ENV NODE_ENV=production

# ¡ESTA ES LA LLAVE! Le damos 4GB de RAM a Node para que no se ahogue
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Horneado final de OptimIA (Ahora con el nombre inyectado en el build)
RUN bundle exec rails assets:precompile
# -------------------------------------------------------

# Comando de inicio
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
