require "addressable/uri"
class UpdateDataJob < ApplicationJob
  queue_as :default

  def perform(ext = true)
    Contest.all.each do |contest|
      request_photolist = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=#{contest.category}&cmlimit=500&cmdir=newer&format=json"

      photolist = HTTParty.get(request_photolist, uri_adapter: Addressable::URI).to_a

      photolist = photolist[1][1]['categorymembers']
      unless photolist.nil?
        photolist.each do |photo|
        unless Photo.find_by(pageid: photo['pageid'])
            photoinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&pageids=#{photo['pageid']}&prop=imageinfo&iiprop=user|timestamp|userid&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['imageinfo'][0] # Looks for photoinfo
            creationdate = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&meta=globaluserinfo&guiuser=#{photoinfo['user']}&format=json", uri_adapter: Addressable::URI).to_a[1][1]['globaluserinfo']['registration']
            globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&prop=globalusage&pageids=#{photo['pageid']}&gunamespace=0&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['globalusage'].try(:empty?)

            unless @creator = Creator.find_by(username: photoinfo['user'])
              @creator = Creator.create(username: photoinfo['user'], userid: photoinfo['userid'], creationdate: creationdate)
              @creator.update_attribute(:proveniencecontest, contest.id) if creationdate.to_date == photoinfo['timestamp'].to_date || creationdate.to_date.between?(Date.parse('30/08/2019'), Date.parse('30/09/2019'))
            end
            Photo.create(pageid: photo['pageid'], name: photo['title'], creator: @creator, contest: contest, photodate: photoinfo['timestamp'], usedonwiki: !globalusage)
          end
        end
      end
    end
    if ext == true
      puts 'Inizio a cercare le foto che sono state usate su Wiki'
      Photo.all.each do |photo|
        globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&prop=globalusage&pageids=#{photo.pageid}&gunamespace=0&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo.pageid.to_s]['globalusage'].try(:empty?)
        if !globalusage != photo.usedonwiki
          photo.update_attribute(:usedonwiki, !globalusage)
        end
      end
    end 
  end
end