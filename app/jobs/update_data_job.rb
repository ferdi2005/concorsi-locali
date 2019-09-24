require "addressable/uri"
class UpdateDataJob < ApplicationJob
  queue_as :default

  def perform
    start = Time.now
    Contest.includes(:photos).each do |contest|
      puts 'Ottengo la categoria...'
      request_photolist = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=#{contest.category}&cmlimit=500&cmdir=newer&format=json"
      photolist = HTTParty.get(request_photolist, uri_adapter: Addressable::URI).to_a
      if photolist[2].nil?
        photolist = photolist[1][1]['categorymembers']
      else
        cmcontinue = photolist[1][1]['cmcontinue']
        continue = photolist[1][1]['continue']
        photolist = photolist[2][1]['categorymembers']
      end
       unless photolist.nil?
        while continue == '-||'
          puts 'Ottengo la continuazione della categoria...'
          new_request_photolist = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=#{contest.category}&cmlimit=500&cmdir=newer&cmcontinue=#{cmcontinue}&format=json"
          new_photolist = HTTParty.get(new_request_photolist, uri_adapter: Addressable::URI).to_a
          unless new_photolist.nil?
            if new_photolist[2].nil?
              new_photolist = new_photolist[1][1]['categorymembers']
              noph = true
            else
              cmcontinue = new_photolist[1][1]['cmcontinue']
              continue = new_photolist[1][1]['continue']
              new_photolist = new_photolist[2][1]['categorymembers']
            end      
            unless new_photolist.nil?
              puts 'Sommo le liste di foto...'
              photolist += new_photolist
            end
          end
          break if noph
        end
        puts 'Inizio a processare le singole foto...'
        unless photolist.count == contest.photos.count
          photolist.each do |photo|
            unless Photo.find_by(pageid: photo['pageid'])
                photoinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&pageids=#{photo['pageid']}&prop=imageinfo&iiprop=user|timestamp|userid&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['imageinfo'][0] # Looks for photoinfo
                globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&prop=globalusage&pageids=#{photo['pageid']}&gunamespace=0&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['globalusage'].try(:empty?)
                puts "Foto: #{photo['title']} di #{photoinfo['user']}..."
                unless (@creator = Creator.find_by(username: photoinfo['user']) || @creator = Creator.find_by(userid: photoinfo['userid']))
                    photoinfo['user'] = photoinfo['user'].gsub!('&', '%26')
                  unless photoinfo['user'].nil?
                    begin
                      @creationdate = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&meta=globaluserinfo&guiuser=#{photoinfo['user']}&format=json", uri_adapter: Addressable::URI).to_a[1][1]['globaluserinfo']['registration']
                    rescue NoMethodError => e
                      puts e
                      # dummy date
                      @creationdate = '2009-01-01'
                    end
                    puts "Creo l'utente #{photoinfo['user']}"
                    @creator = Creator.create(username: photoinfo['user'], userid: photoinfo['userid'], creationdate: @creationdate)
                    unless @creationdate.nil?
                      @creator.update_attribute(:proveniencecontest, contest.id) if @creationdate.to_date == photoinfo['timestamp'].to_date || @creationdate.to_date.between?(Date.parse('30/08/2019'), Date.parse('30/09/2019'))  
                    end                
                  end
                end
                  Photo.create(pageid: photo['pageid'], name: photo['title'], creator: @creator, contest: contest, photodate: photoinfo['timestamp'], usedonwiki: !globalusage)
                  break if photolist.count == contest.photos.count
            end
        end
      end
      end
    end
    
    puts 'Inizio salvataggio del conto dei creatori.'
      Contest.all.each do |contest|
        @creators = Creator.includes(:photos).select { |m| m.photos.where(contest: contest).any? }.count

        contest.update_attribute(:creators, @creators)
        creatorsapposta = Creator.where(proveniencecontest: contest.id).count
        contest.update_attribute(:creatorsapposta, creatorsapposta) 
      end
      puts 'Tempo di esecuzione'
      puts Time.now - start
  end
end