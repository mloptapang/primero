Rails.application.config.middleware.insert_before(Warden::JWTAuth::Middleware, JwtTokenSetter)
