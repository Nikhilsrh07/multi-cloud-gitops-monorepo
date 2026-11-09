FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY . .

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app .
USER node
EXPOSE 8080
CMD ["node", "app.js"]
