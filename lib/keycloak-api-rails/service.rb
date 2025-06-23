module Keycloak
  class Service
    
    def initialize(key_resolver)
      @key_resolver                          = key_resolver
      @logger                                = Keycloak.config.logger
      @token_expiration_tolerance_in_seconds = Keycloak.config.token_expiration_tolerance_in_seconds
    end

    def decode_and_verify(token)
      unless token.nil? || token&.empty?
        # First decode without verification to check expiration with our custom logic
        payload, header = JWT.decode(token, nil, false)

        if expired?(payload)
          raise TokenError.expired(token)
        end
        
        # Get the appropriate public key for verification
        public_key = find_public_key(header)
        
        # Then verify signature
        decoded_token = JWT.decode(token, public_key, true, 
                                 algorithm: determine_algorithm(token),
                                 verify_expiration: false) # We handle expiration ourselves
        
        decoded_token[0]
      else
        raise TokenError.no_token(token)
      end
    rescue JWT::VerificationError => e
      raise TokenError.verification_failed(token, e)
    rescue JWT::DecodeError => e
      raise TokenError.invalid_format(token, e)
    end

    def read_token(uri, headers)
      Helper.read_token_from_query_string(uri) || Helper.read_token_from_headers(headers)
    end

    private

    def find_public_key(header)
      jwk_set = @key_resolver.find_public_keys
      
      # Handle the case where the resolver returns a simple public key (like in tests)
      return jwk_set unless jwk_set.respond_to?(:keys)
      
      # Find the key by kid (key ID) from the JWT header
      kid = header['kid']
      if kid
        # Find the JWK with matching kid
        jwk = jwk_set.find { |key| key.kid == kid }
        raise JWT::DecodeError, "Unable to find key with kid: #{kid}" unless jwk
        jwk.verify_key
      else
        # If no kid is specified, use the first available key
        first_jwk = jwk_set.first
        raise JWT::DecodeError, "No keys available in JWK set" unless first_jwk
        first_jwk.verify_key
      end
    end

    def determine_algorithm(token)
      # Extract algorithm from JWT headers without verification
      headers = JWT.decode(token, nil, false)[1]
      headers['alg'] || 'RS256'
    rescue
      'RS256' # Default fallback
    end

    def expired?(token)
      return false unless token["exp"]
      token_expiration = Time.at(token["exp"])
      token_expiration < Time.now + @token_expiration_tolerance_in_seconds
    end
  end
end
