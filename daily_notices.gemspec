Gem::Specification.new do |s|
  s.name = 'daily_notices'
  s.version = '0.1.0'
  s.summary = 'daily_notices'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('activity-logger', '~> 0.3', '>=0.3.2')
  s.signing_key = '../privatekeys/daily_notices.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/daily_notices'
end
