# Dockerfile definitivo para OptimIA - Versión Disruptive SW
FROM ruby:3.4.4-slim as base

# Instalación de dependencias de sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    git \
    curl \
    libvips-dev \
    pkg-config

# Instalar Node.js y las herramientas de gestión (pnpm es la clave aquí)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global pnpm

WORKDIR /app

# Instalación de gemas de Ruby (Esto ya está en caché, será rápido)
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# --- SECCIÓN FRONTEND PARA OPTIMIA ---
# Instalamos las dependencias de diseño (Vite, Vue, etc.)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile
# ------------------------------------

# Copiar el resto de la aplicación
COPY . .

# --- SECCIÓN DE COMPILACIÓN FINAL ---
ARG SECRET_KEY_BASE
ARG FRONTEND_URL
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
ENV FRONTEND_URL=$FRONTEND_URL
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Aquí es donde se hornean tus logos de OptimIA
RUN bundle exec rails assets:precompile
# ------------------------------------

# Comando de inicio
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
