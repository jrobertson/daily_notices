Gem::Specification.new do |s|
  s.name = 'daily_notices'
  s.version = '0.7.1'
  s.summary = 'A public facing noticeboard which is centered around an ' + 
      'RSS feed.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/daily_notices.rb']
  s.add_runtime_dependency('rss_creator', '~> 0.4', '>=0.4.2')
  s.add_runtime_dependency('dx_sliml', '~> 0.1', '>=0.1.8')
  s.add_runtime_dependency('rx_sliml', '~> 0.2', '>=0.2.1')
  s.add_runtime_dependency('rss_sliml', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/daily_notices.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/daily_notices'
end
