ARG BUILDER_IMAGE="hexpm/elixir:1.14.1-erlang-25.2.1-debian-bullseye-20230109-slim"
ARG RUNNER_IMAGE="debian:bullseye-20231009-slim"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && apt-get install -y build-essential git \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
  mix local.rebar --force

ENV MIX_ENV="prod"
ENV ROLE="app"

COPY mix.exs mix.lock endpoint_prod.sh ./

RUN mix deps.get --only $MIX_ENV \
  && mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/

COPY ./server/config /app/config

RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN apt-get update -y && apt-get install -y npm

RUN mix assets.deploy
RUN echo y | mix ua_inspector.download
RUN mix compile

COPY config/runtime.exs config/
COPY rel rel

RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE} AS runner

RUN apt-get update -y \
  && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean \
  && rm -f /var/lib/apt/lists/*_* \
  && hostname $CANONICAL_HOST \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

FROM runner AS stage1

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/mave_metrics ./
COPY --from=builder --chown=nobody:root --chmod=0755 /app/endpoint_prod.sh /app/endpoint_prod.sh

FROM stage1 AS stage2

USER nobody

CMD ["/app/endpoint_prod.sh"]

# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"
