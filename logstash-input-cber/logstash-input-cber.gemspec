Gem::Specification.new do |s|
  s.name          = 'logstash-input-cber'
  s.version       = '0.1.0'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'Write a short summary, because Rubygems requires one.'
  s.description   = 'Write a longer description or delete this line.'
  s.homepage      = 'http://carbonblack.com'
  s.authors       = ['Zachary Estep']
  s.email         = 'zestep@carbonblack.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['jar-dependencies/*/*.jar','*.jar','lib/inputs/*.jar','lib/**/*','lib/inputs/target/*/*/*/*','lib/inputs/*/*/*/*','lib/inputs/target/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  #s.add_development_dependency 'jar-dependencies', '~> 0.3.2'
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'march_hare'
  s.add_runtime_dependency 'json'
  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
end
