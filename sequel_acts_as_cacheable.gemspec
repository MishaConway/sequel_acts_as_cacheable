Gem::Specification.new do |s|
  s.name    = 'sequel_acts_as_cacheable'
  s.version = '1.4'
  s.summary = 'Memcaching for sequel models.'
  s.license = 'MIT'

  s.author   = 'Misha Conway'
  s.email    = 'MishaAConway@gmail.com'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end