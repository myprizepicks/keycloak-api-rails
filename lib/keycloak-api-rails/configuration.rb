# frozen_string_literal: true

module Keycloak
  class Configuration
    attr_accessor :server_url, :realm_id, :token_expiration_tolerance_in_seconds, :public_key_cache_ttl,
                  :custom_attributes, :logger, :ca_certificate_file
  end
end
