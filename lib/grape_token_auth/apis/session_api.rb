module GrapeTokenAuth
  module SessionsAPICore
    def self.included(base)
      base.helpers do
        def find_resource(env, mapping)
          token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
          token_authorizer.find_resource(mapping)
        end

        def resource_class(mapping)
          GrapeTokenAuth.configuration.scope_to_class(mapping)
        end
      end

      base.post '/sign_in' do
        resource = ResourceFinder.find(base.resource_scope, params)
        if resource && resource.valid_password?(params[:password])
          status 200
          present data: resource
        else
          error!({ errors: 'Invalid login credentials. Please try again.',
                   status: 'error' }, 401)
        end
      end

      base.delete '/sign_out' do
        resource = find_resource(env, base.resource_scope)

        if resource
          resource.tokens.delete(env[Configuration::CLIENT_KEY])
          resource.save
          status 200
        else
          status 404
        end
      end
    end
  end

  class SessionsAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include SessionsAPICore
  end
end