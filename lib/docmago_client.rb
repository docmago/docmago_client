require "httparty"
require "tempfile"

require 'docmago_client/version'
require 'docmago_client/exception'
require 'docmago_client/error'

if defined?(Rails)
  if Rails.respond_to?(:version) && Rails.version =~ /^3/
    require 'docmago_client/railtie'
  else
    raise "docmago_client #{DocmagoClient::VERSION} is not compatible with Rails 2.3 or older"
  end
end

module DocmagoClient
  include HTTParty
  
  base_uri ENV["DOCMAGO_URL"] || "https://docmago.com/api/"
  
  def self.api_key(key = nil)
    default_options[:api_key] = key ? key : default_options[:api_key] || ENV["DOCMAGO_API_KEY"]
    default_options[:api_key] || raise(DocmagoClient::Error::NoApiKeyProvidedError.new("No API key provided"))
  end

  def self.create!(options = {})
    raise ArgumentError.new "please pass in an options hash" unless options.is_a? Hash
    self.create(options.merge({:raise_exception_on_failure => true}))
  end

  # when given a block, hands the block a TempFile of the resulting document
  # otherwise, just returns the response
  def self.create(options = { })
    raise ArgumentError.new "please pass in an options hash" unless options.is_a? Hash
    if options[:content].nil? || options[:content].empty?
      raise DocmagoClient::Error::NoContentError.new("must supply :content")
    end

    default_options = {
      :name                       => "default",
      :type                       => "pdf",
      :test_mode                  => false,
      :raise_exception_on_failure => false
    }
    options = default_options.merge(options)
    raise_exception_on_failure = options[:raise_exception_on_failure]
    options.delete :raise_exception_on_failure
    
    response = post("/documents", body: { document: options }, basic_auth: { username: api_key })

    if raise_exception_on_failure && !response.success?
      raise DocmagoClient::Exception::DocumentCreationFailure.new response.body, response.code
    end

    if block_given?
      ret_val = nil
      Tempfile.open("docmago") do |f|
        f.sync = true
        f.write(response.body)
        f.rewind

        ret_val = yield f, response
      end
      ret_val
    else
      response
    end
  end

  def self.list_docs!(options = { })
    raise ArgumentError.new "please pass in an options hash" unless options.is_a? Hash
    self.list_docs(options.merge({:raise_exception_on_failure => true}))
  end

  def self.list_docs(options = { })
    raise ArgumentError.new "please pass in an options hash" unless options.is_a? Hash
    default_options = {
      :page     => 1,
      :per_page => 100,
      :raise_exception_on_failure => false
    }
    options = default_options.merge(options)
    raise_exception_on_failure = options[:raise_exception_on_failure]
    options.delete :raise_exception_on_failure

    response = get("/documents", :query => options, :basic_auth => { :username => api_key })
    if raise_exception_on_failure && !response.success?
      raise DocmagoClient::Exception::DocumentListingFailure.new response.body, response.code
    end

    response
  end
end