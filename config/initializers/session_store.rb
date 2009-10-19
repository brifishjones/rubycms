# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rubycms_session',
  :secret      => 'be252d1c384c52e2d3d412e6db52d63d034ed79192051e83d19345c999f12db8eca7728c7fa84c20c9b9734ee313121568bcc9ee41d0e6751a934e06878fb541'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
