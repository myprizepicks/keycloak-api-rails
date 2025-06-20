module Keycloak
  class Service
    
    def initialize(key_resolver)
      @key_resolver                          = key_resolver
      @logger                                = Keycloak.config.logger
      @token_expiration_tolerance_in_seconds = Keycloak.config.token_expiration_tolerance_in_seconds
    end

    def decode_and_verify(token)
      unless token.nil? || token&.empty?
        public_key    = @key_resolver.find_public_keys
        # First decode without verification to check expiration with our custom logic
        payload = JWT.decode(token, nil, false)[0]
        
        if expired?(payload)
          raise TokenError.expired(token)
        end
        
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
