FROM node:18-alpine AS base

FROM base AS builder
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN yarn global add turbo@2.1.2
COPY . .

RUN turbo prune web --docker
RUN turbo prune api --docker


FROM base AS installer
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app


COPY --from=builder /app/out/json/ .
RUN yarn install


COPY --from=builder /app/out/full/ .
RUN yarn turbo run build

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 monorepo
USER monorepo

COPY --from=installer --chown=monorepo:nodejs /app .

CMD node apps/api/dist/main.js