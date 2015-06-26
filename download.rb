require 'json'

require 'google/api_client'
require 'google/api_client/auth/installed_app'
require 'google/api_client/client_secrets'

require 'nokogiri'

require 'global_phone'
GlobalPhone.db_path = 'global_phone.json'

def client
  Google::APIClient.new(
    :application_name => 'fbarchiver',
    :application_version => '0.0.1',
  ).tap do |c|
    client_secrets = Google::APIClient::ClientSecrets.load
    flow = Google::APIClient::InstalledAppFlow.new(
      :client_id => client_secrets.client_id,
      :client_secret => client_secrets.client_secret,
      :scope => ['https://www.google.com/m8/feeds/'],
    )
    c.authorization = flow.authorize
  end
end

def download client
  [].tap do |results|
    endpoint = 'https://www.google.com/m8/feeds/contacts/default/full/'

    while r = client.execute(:http_method => :get, :uri => endpoint)
      puts "Retrieved #{endpoint} ..."

      rn = Nokogiri::XML r.body
      next_link = rn.at_css 'feed > link[rel=next]'
      break unless next_link

      endpoint = next_link['href']
      results << rn
    end
  end
end

def merge results
  results
    .map { |d| d.css 'entry' }
    .flatten
    .reject { |e| (e > 'gd|phoneNumber').nil? }
end

def nor

def normalize entries
  entries.map do |e|
    pns = (e > 'gd|phoneNumber').map { |e| GlobalPhone.normalize e.text }
    "#{(e > 'title').text} : #{pns.join ', '}"
  end
end

def parse results
  results.map do |e|
    {
      id: e.at_css('id').text,
      name: e.at_css('title').text,
    }.tap do |h|
      (pn = e.at_css 'gd|phoneNumber') && h['pn'] = pn.text
    end
  end
end
