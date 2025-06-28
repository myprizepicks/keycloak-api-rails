# frozen_string_literal: true

module Keycloak
  class PublicKeyResolver
    def initialize(http_client, realm_id)
      @realm_id    = realm_id
      @http_client = http_client
    end

    def find_public_keys
      jwks_hash = @http_client.get(@realm_id, 'protocol/openid-connect/certs')
      JWT::JWK::Set.new(jwks_hash)
    end
  end
end
