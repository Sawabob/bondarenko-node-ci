FROM node:22-bookworm-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY index.js ./
RUN npm run build
USER node
EXPOSE 3000
CMD ["node", "index.js"]
