#!/usr/bin/env ruby
### grab metrics from newrelic and put them into graphite
### David Lutz
### 2012-06-15
### to use:  apt-get install ruby
### apt-get install build-essential
### apt-get install libcurl3 libcurl3-gnutls libcurl4-openssl-dev
### gem install curl curb json xmlsimple --no-ri --no-rdoc

require 'rubygems'
require 'curb'
require 'json'
require 'socket'
require 'xmlsimple'
require './config.rb'
require './SendGraphite.rb'


t=Time.now.utc
$timenow=t.to_i


def GetThresholdMetrics(application, appname)
  begin
	threshURL= "https://rpm.newrelic.com/accounts/"+$account+"/applications/"+application+"/threshold_values.xml"

	response = Curl::Easy.perform(threshURL) do |curl| curl.headers["x-api-key"] = $apikey
	end

	body=response.body_str
	data = XmlSimple.xml_in(body, { 'KeyAttr' => 'threshold_values' })

	data['threshold_value'].each do |item|
		message = "newrelic." + appname + "." + item['name'].gsub(" ","_") + " " + item['metric_value'] + " " + $timenow.to_s
#		puts message
		Sendit message
	end
  rescue 
#	puts application + appname + "borked"
  end
end



##get a list of applications for account X
applicationsURL = "https://rpm.newrelic.com/accounts/"+$account+"/applications.xml"
appsresponse = Curl::Easy.perform(applicationsURL) do |curl| curl.headers["x-api-key"] = $apikey
end

appsbody=appsresponse.body_str
#puts appsbody

appdata = XmlSimple.xml_in(appsbody, { 'KeyAttr' => 'applications' })

## big ole loop over the returned XML 

appdata['application'].each do |item|
	appname = item['name'][0].to_s
	application=item['id'].to_s.gsub!(/\D/,"").to_i.to_s

	GetThresholdMetrics application, appname
end

