set :stages, %w(production sandbox)
set :default_stage, "production"
require 'capistrano/ext/multistage'