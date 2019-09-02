require "addressable/uri"
class UpdateDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Contest.all.each do |contest|
      request_photolist = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=#{contest.category}&cmlimit=500&format=json"

      photolist = HTTParty.get(request_photolist, uri_adapter: Addressable::URI).to_a

      photolist = photolist[1][1]['categorymembers']

      photolist.each do |photo|
      unless Photo.find_by(pageid: photo['pageid'])
          photoinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&titles=#{photo['title']}&prop=imageinfo&iiprop=user|timestamp|userid&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['imageinfo'][0] # Looks for photoinfo

          globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&prop=globalusage&titles=#{photo['title']}.jpg&gunamespace=0&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages']['-1']['globalusage'].empty?

          unless @creator = Creator.find_by(username: photoinfo['user'])
            @creator = Creator.create(username: photoinfo['user'], userid: photoinfo['userid'])
          end
          Photo.create(pageid: photo['pageid'], name: photo['title'], creator: @creator, contest: contest, photodate: photoinfo['timestamp'], usedonwiki: !globalusage)
        end
      end
    end
  end
end
