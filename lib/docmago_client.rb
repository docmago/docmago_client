require 'typhoeus'
require 'tempfile'

require 'docmago_client/version'
require 'docmago_client/exception'
require 'docmago_client/error'
require 'docmago_client/html_resource_archiver'

if defined?(Rails)
  require 'docmago_client/railtie'
end

module DocmagoClient
  class << self
    attr_writer :base_uri, :api_key, :logger

    def logger
      @logger ||= Logger.new($stdout)
    end

    def base_uri
      @base_uri || ENV['DOCMAGO_URL'] || 'https://docmago.com/api'
    end

    def api_key
      @api_key || ENV['DOCMAGO_API_KEY']
    end
  end

  # when given a block, hands the block a TempFile of the resulting document
  # otherwise, just returns the response
  def self.create(options = {})
    raise ArgumentError, 'please pass in an options hash' unless options.is_a? Hash
    if options[:content].nil? || options[:content].empty?
      raise DocmagoClient::Error::NoContentError.new, 'must supply :content'
    end

    default_options = {
      name: 'default',
      type: 'pdf',
      integrity_check: true
    }

    options = default_options.merge(options)

    if options[:zip_resources]
      tmp_dir = Dir.mktmpdir
      begin
        resource_archiver = HTMLResourceArchiver.new(options)
        options[:content] = File.new(resource_archiver.create_zip("#{tmp_dir}/document.zip"))
        options.delete :assets

        response = Typhoeus.post "#{base_uri}/documents", body: {
          auth_token: api_key,
          document: options.slice(:content, :name, :type, :test_mode)
        }
      ensure
        FileUtils.remove_entry_secure tmp_dir
      end
    else
      response = Typhoeus.post "#{base_uri}/documents", body: {
        auth_token: api_key,
        document: options.slice(:content, :name, :type, :test_mode)
      }
    end

    if options[:integrity_check] && response.headers['X-Docmago-Checksum'] != Digest::MD5.hexdigest(response.body)
      raise DocmagoClient::Error::IntegrityCheckError.new, 'File corrupt (invalid MD5 checksum)'
    end

    response
  end
end
