FROM elixir:1.14.1

WORKDIR /app

RUN apt-get update -y \
  && apt-get install -y inotify-tools postgresql-client gcc g++ make \
  && mix local.hex --force \
  && mix local.rebar --force

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs

COPY ./ ./

CMD ["/bin/bash", "/app/run.sh"]
