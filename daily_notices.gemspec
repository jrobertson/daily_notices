Gem::Specification.new do |s|
  s.name = 'daily_notices'
  s.version = '0.2.4'
  s.summary = 'A public facing noticeboard which is centered around an RSS feed.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/daily_notices.rb']
  s.add_runtime_dependency('rss_creator', '~> 0.2', '>=0.2.7')
  s.signing_key = '../privatekeys/daily_notices.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/daily_notices'
end
