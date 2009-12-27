# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# rubycms specific constants
require 'config/rubycms_prefs'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "capistrano"
  config.gem "capistrano-ext", :lib => false
  config.gem "cgi_multipart_eof_fix"
  config.gem "crypt", :lib => false
  config.gem "daemons"
  config.gem "fastthread"
  config.gem "gem_plugin"
  config.gem "highline"
  config.gem "hpricot"
  config.gem "libxml-ruby", :lib => false
  config.gem "mongrel"
  config.gem "mongrel_cluster", :lib => false
  config.gem "net-scp", :lib => false
  config.gem "net-sftp", :lib => false
  config.gem "net-ssh", :lib => false
  config.gem "net-ssh-gateway", :lib => false
  config.gem "palmtree", :lib => false
  config.gem "passenger", :lib => false
  config.gem "rack"
  config.gem "rails"
  config.gem "rake"
  config.gem "rmagick"
  config.gem "rspec", :lib => false
  config.gem "rubygems-update", :lib => false
  config.gem "ruby-net-ldap", :lib => false
  config.gem "rubyzip", :lib => false
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end
