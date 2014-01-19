Gem::Specification.new do |s|
  s.name        = 'aasm_actionable'
  s.version     = '1.0.0'
  s.date        = '2014-01-03'
  s.summary     = "AASM Actionable"
  s.description = "Rails extension to render appropriate workflow actions"
  s.authors     = ["Brendan MacDonell"]
  s.email       = 'brendan@macdonell.net'
  s.files       = Dir.glob("{app,lib}/**/*") + %w(README.md)
  s.homepage    = 'http://rubygems.org/gems/aasm_actionable'
  s.license     = 'MIT'

  s.add_runtime_dependency 'rails', ['~> 4.0']
  s.add_runtime_dependency 'aasm', ['~> 3.0']
  s.add_runtime_dependency 'pundit', ['~> 0.2.1']
end
