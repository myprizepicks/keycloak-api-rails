# frozen_string_literal: true

RSpec.describe Keycloak::Helper do
  describe '#create_url_with_token' do
    let(:uri)   { 'http://www.an-url.io' }
    let(:token) { 'aToken' }

    before(:each) do
      @url_with_token = Keycloak::Helper.create_url_with_token(uri, token)
    end

    context 'when the uri has no query string yet' do
      it 'returns an url with the provided token' do
        expect(@url_with_token).to eq "#{uri}?authorizationToken=#{token}"
      end
    end

    context 'when the uri already has no query strings' do
      context 'but no token yet' do
        let(:uri)   { 'http://www.an-url.io?firstName=ouioui&lastName=nonnon' }
        it 'returns an url with all the query string and the token' do
          expect(@url_with_token).to eq "#{uri}&authorizationToken=#{token}"
        end
      end

      context 'including a token' do
        let(:uri)   { 'http://www.an-url.io?authorizationToken=ouioui&lastName=nonnon' }
        it 'returns an url with all the query string and the new token' do
          expect(@url_with_token).to eq "http://www.an-url.io?lastName=nonnon&authorizationToken=#{token}"
        end
      end
    end
  end

  describe '#read_token_from_headers' do
    context 'when HTTP_AUTHORIZATION header is present' do
      it 'returns the token from HTTP_AUTHORIZATION header' do
        headers = { 'HTTP_AUTHORIZATION' => 'Bearer mytoken123' }
        expect(Keycloak::Helper.read_token_from_headers(headers)).to eq 'mytoken123'
      end
    end

    context 'when Authorization header is present' do
      it 'returns the token from Authorization header' do
        headers = { 'Authorization' => 'Bearer mytoken456' }
        expect(Keycloak::Helper.read_token_from_headers(headers)).to eq 'mytoken456'
      end
    end

    context 'when both headers are present' do
      it 'prioritizes HTTP_AUTHORIZATION header' do
        headers = {
          'HTTP_AUTHORIZATION' => 'Bearer http_token',
          'Authorization' => 'Bearer auth_token'
        }
        expect(Keycloak::Helper.read_token_from_headers(headers)).to eq 'http_token'
      end
    end

    context "when token doesn't have Bearer prefix" do
      it 'returns the token as is' do
        headers = { 'HTTP_AUTHORIZATION' => 'mytoken789' }
        expect(Keycloak::Helper.read_token_from_headers(headers)).to eq 'mytoken789'
      end
    end

    context 'when no headers are present' do
      it 'returns an empty string' do
        headers = {}
        expect(Keycloak::Helper.read_token_from_headers(headers)).to eq ''
      end
    end
  end
end
