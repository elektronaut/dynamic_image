# Be sure to restart your server when you modify this file.

# Creates a local storage layer in db/shrouded:
Shrouded::Storage.layers << Shrouded::Layer.new(
  Fog::Storage.new({ provider: 'Local', local_root: Rails.root.join('db', 'shrouded') }),
  path: Rails.env
)

# You can also add cloud storage.
# Shrouded::Storage.layers << Shrouded::Layer.new(
#   Fog::Storage.new({
#     provider:              'AWS',
#     aws_access_key_id:     AWS_ACCESS_KEY_ID,
#     aws_secret_access_key: AWS_SECRET_ACCESS_KEY
#   }),
#   delayed: true
# )
