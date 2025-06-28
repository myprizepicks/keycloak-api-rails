# frozen_string_literal: true

module Keycloak
  class PublicKeyResolverStub
    def find_public_keys
      # Create a mock JWK set that wraps the RSA key
      key = OpenSSL::PKey::RSA.generate(1024)
      jwk = JWT::JWK.new(key)
      JWT::JWK::Set.new(jwk)
    end
  end
end
