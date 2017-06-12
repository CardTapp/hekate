module Hekate
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'lib/tasks'
    end

    config.before_configuration do
      Engine.load_environment
    end
  end
end
