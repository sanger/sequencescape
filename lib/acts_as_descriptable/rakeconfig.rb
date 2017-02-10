ProjectInfo = {
  name: 'acts_as_descriptoable',
  description: 'Allows model fields and values to be dynamically extended.',
  homepage: 'http://www.sanger.ac.uk/Users/mw4/ruby/rails/acts_as_descriptable',
  version: '1.0',
  author_link: 'http://www.sanger.ac.uk/Users/mw4/',
  author_name: 'Matt Wood'
}

ReleaseFiles = FileList[
  'lib/**/*.rb', '*.txt', 'README', 'Rakefile', 'rakeconfig.rb',
  'rake/**/*', 'test/**/*.rb', '*.rb', 'test/**/*.xml', 'doc/**/*', 'html/**/*'
].exclude(/\bCVS\b|~$/)

PluginPackageFiles = FileList[
  'lib/**/*.rb', '*.txt', 'README', 'Rakefile', 'rakeconfig.rb',
  'rake/**/*', 'test/**/*.rb', '*.rb', 'test/**/*.xml'
].exclude(/\bCVS\b|~$/)
