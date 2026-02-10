FROM node:22-alpine
WORKDIR /app
RUN apk add --no-cache curl
COPY package.json package-lock.json* ./
RUN npm install --production
COPY . .
RUN npx prisma generate
ENV PORT=3000
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --retries=5 \
  CMD curl -fsS http://localhost:3000/api/health || exit 1
CMD ["npm","start"]
