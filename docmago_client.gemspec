$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "docmago_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "docmago_client"
  s.version     = DocmagoClient::VERSION
  s.authors     = ["Jan Habermann"]
  s.email       = ["jan@habermann24.com"]
  s.homepage    = "http://github.com/docmago/docmago_client"
  s.summary     = "Client for the Docmago API (www.docmago.com)"
  s.description = "Makes it easy to create PDF documents through the Docmago API."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  
  s.add_dependency "httparty", ">=0.7.0"
  
  s.add_development_dependency "rails", "~> 3.2.5"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "capybara"
end
