Gem::Specification.new do |s|
  s.name = 'app_signer'
  s.version = '0.0.1'
  s.summary = 'Easily sign an iOS .app package.'
  s.description = 'Sign an iOS .app package with a given provisioning profile.'
  s.authors = ['Andrew Carter', 'WillowTree Apps']
  s.email = ['andrew.carter@willowtreeapps.com']
  s.files = ['lib/app_signer.rb', 'README.md']
  s.homepage = 'http://rubygems.org/gems/app-sign'
  s.license = 'MIT'
  s.executables << 'app_signer'
  s.has_rdoc = 'yard'
  s.add_runtime_dependency 'plist', '3.1.0'
  s.add_runtime_dependency 'trollop', '2.0'
end
