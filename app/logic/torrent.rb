class Torrent
  PORT = 9091
  HOST = "http://localhost"

  class << self
    def get ids = nil, options = {}
      options[:ids] = ids if ids
      options[:fields] ||= ["id", "name", "percentDone", "downloadDir"]
      torrents = transform_response(request("torrent-get", options))
      torrents["arguments"]["torrents"]
    end

    def add url, options = {}
      options[:filename] = url
      torrent = transform_response(request("torrent-add", options))
      torrent = torrent["arguments"]
      torrent["torrent-added"] || torrent["torrent-duplicate"]
    end

    def remove ids, options = {}
      options[:ids] = ids
      options["delete-local-data"] = true unless options["delete-local-data"].present?
      transform_response(request("torrent-remove", options))
    end

    def stop ids, options = {}
      options[:ids] = ids.respond_to?(:length) ? ids : [ids]
      request("torrent-stop", options)
    end

    def start ids, options = {}
      options[:ids] = ids.respond_to?(:length) ? ids : [ids]
      request("torrent-start", options)
    end

    def request method, options
      arguments = { method: method, arguments: options }
      RestClient::Request.execute(
        url: _url,
        method: :post,
        content_type: :json,
        payload: arguments.to_json,
        headers: { "X-Transmission-Session-Id" => @session }
      )
    rescue RestClient::Conflict => ex
      save_session(ex.response)
      retry
    end

    private

    def save_session response
      @session = response.match(/<code>(.*)<\/code>/)[1].split(":").last.strip
    end

    def transform_response response
      attributes = ActiveSupport::JSON.decode(response)
      ActiveSupport::HashWithIndifferentAccess.new(attributes)
    end

    def _url
      "#{HOST}:#{PORT}/transmission/rpc"
    end
  end
end
