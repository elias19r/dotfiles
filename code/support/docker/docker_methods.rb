# irb -r ./docker_methods.rb

# Postgres

def docker_create_postgres(app_name, version: "17.5", port: "5432", user: nil, password: nil)
  user ||= app_name
  password ||= app_name

  %x[
    docker network create \
      #{app_name}-postgres-network
  ]
  %x[
    docker container create \
      --name #{app_name}-postgres-server \
      --network #{app_name}-postgres-network \
      -e POSTGRES_USER=#{user} \
      -e POSTGRES_PASSWORD=#{password} \
      -v ${HOME}/code/support/docker/#{app_name}/volumes/postgres:/var/lib/postgresql/data \
      -p #{port}:5432 \
      postgres:#{version}
  ]
  %x[
    docker container create \
      --name #{app_name}-postgres-psql \
      --network #{app_name}-postgres-network \
      -e PGPASSWORD=#{password} \
      -it \
      postgres:#{version} \
      psql -h #{app_name}-postgres-server -U #{user}
  ]
end

def docker_remove_postgres(app_name)
  docker_stop_postgres(app_name)

  _docker_remove("#{app_name}-postgres-psql")
  _docker_remove("#{app_name}-postgres-server")
  _docker_network_remove("#{app_name}-postgres-network")
end

def docker_start_postgres(app_name)
  _docker_start("#{app_name}-postgres-server")
  sleep 10
  _docker_start("#{app_name}-postgres-psql")
end

def docker_stop_postgres(app_name)
  _docker_stop("#{app_name}-postgres-psql")
  _docker_stop("#{app_name}-postgres-server")
end

# Redis

def docker_create_redis(app_name, version: "6.2.14", port: "6379")
  %x[
    docker network create \
      #{app_name}-redis-network
  ]
  %x[
    docker container create \
      --name #{app_name}-redis-server \
      --network #{app_name}-redis-network \
      -v ${HOME}/code/support/docker/#{app_name}/volumes/redis:/data \
      -p #{port}:6379 \
      redis:#{version} \
      redis-server --save 60 1 --loglevel warning
  ]
  %x[
    docker container create \
      --name #{app_name}-redis-cli \
      --network #{app_name}-redis-network \
      -it \
      redis:#{version} \
      redis-cli -h #{app_name}-redis-server
  ]
end

def docker_remove_redis(app_name)
  docker_stop_redis(app_name)

  _docker_remove("#{app_name}-redis-cli")
  _docker_remove("#{app_name}-redis-server")
  _docker_network_remove("#{app_name}-redis-network")
end

def docker_start_redis(app_name)
  _docker_start("#{app_name}-redis-server")
  sleep 10
  _docker_start("#{app_name}-redis-cli")
end

def docker_stop_redis(app_name)
  _docker_stop("#{app_name}-redis-cli")
  _docker_stop("#{app_name}-redis-server")
end

# RabbitMQ

def docker_create_rabbitmq(app_name, version: "3.12", port: "5672")
  %x[
    docker network create \
      #{app_name}-rabbitmq-network
  ]
  %x[
    docker container create \
      --name #{app_name}-rabbitmq-server \
      --network #{app_name}-rabbitmq-network \
      --hostname #{app_name}-rabbitmq-server \
      -v ${HOME}/code/support/docker/#{app_name}/volumes/rabbitmq:/var/lib/rabbitmq \
      -p #{port}:5672 \
      -p 1#{port}:15672 \
      rabbitmq:#{version}-management
  ]
end

def docker_remove_rabbitmq(app_name)
  docker_stop_rabbitmq(app_name)

  _docker_remove("#{app_name}-rabbitmq-server")
  _docker_network_remove("#{app_name}-rabbitmq-network")
end

def docker_start_rabbitmq(app_name)
  _docker_start("#{app_name}-rabbitmq-server")
end

def docker_stop_rabbitmq(app_name)
  _docker_stop("#{app_name}-rabbitmq-server")
end

# Helper

def docker_start(app_name, *services)
  services.each do |service|
    case service.to_sym
    when :postgres then docker_start_postgres(app_name)
    when :redis    then docker_start_redis(app_name)
    when :rabbitmq then docker_start_rabbitmq(app_name)
    end
  end
end

def docker_stop(app_name, *services)
  services.each do |service|
    case service.to_sym
    when :postgres then docker_stop_postgres(app_name)
    when :redis    then docker_stop_redis(app_name)
    when :rabbitmq then docker_stop_rabbitmq(app_name)
    end
  end
end

# private

def _docker_start(name)
  %x[docker start #{name}]
end

def _docker_stop(name)
  %x[docker stop #{name}]
end

def _docker_remove(name)
  %x[docker rm #{name}]
end

def _docker_network_remove(name)
  %x[docker network rm #{name}]
end
