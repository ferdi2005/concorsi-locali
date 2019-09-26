class UpdatePhotosCountJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Contest.all.each do |contest|
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
        if contest.photos.count > 500
          while continue == '-||'
            puts 'Ottengo la continuazione della categoria...'
            new_request_photolist = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=#{contest.category}&cmlimit=500&cmdir=newer&cmcontinue=#{cmcontinue}&format=json"
            new_photolist = HTTParty.get(new_request_photolist, uri_adapter: Addressable::URI).to_a
            unless new_photolist.nil?
              if new_photolist[2].nil?
                new_photolist = new_photolist[1][1]['categorymembers']
                continue = false
                @noph = true
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
          end
        end
      end
    contest.update_attribute(:count, photolist.count)
    end
  end
end
