class NumericsController < ApplicationController
    before_action :set_contest
    before_action :set_year

    def totalphotos
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            photocount = @contestyear&.count || 0
        else
            photocount = @year.total || 0
        end
        json = {
            'postfix': 'Fotografie totali',
            'data': {
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def todayphotos
        data = []
        unless @contest == false
            photowithdate = @contest.photos.where(year: @year).group_by_day(:photodate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        else
            photowithdate = Photo.where(year: @year).group_by_day(:photodate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        end
        json = {
            'postfix': 'Fotografie di oggi',
            'data': data
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def totalcreators
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            creatorcount = @contestyear&.creators || 0
        else
            creatorcount = @year.creators || 0
        end
        json = {
            'postfix': 'Partecipanti',
            'data': {
                "value": creatorcount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def totalcreatorsapposta
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            creatorcount = @contestyear&.creatorsapposta&.to_i || 0
        else
            creatorcount = Creator.where.not(proveniencecontest: nil).where(year: @year).count
        end
            json = {
                'postfix': 'Partecipanti iscritti per il concorso',
                'data': {
                    "value": creatorcount
                }
            }
            respond_to do |format|
                format.json { render json: json }
            end
    end

    def todaycreatorsapposta
        data = []
        unless @contest == false
            photowithdate = Creator.where(proveniencecontest: @contest.id, year: @year).group_by_day(:creationdate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        else
            photowithdate = Creator.where(year: @year).group_by_day(:creationdate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        end
        json = {
            'postfix': 'Partecipanti iscritti per il concorso',
            'data': data
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end


    def days
        if Date.today.month == 9
            name = "Fine di WLM"
            date = Date.parse("30 september #{@year.year}").strftime("%Y-%m-%d")
        else
            name = "Inizio di WLM"
            date = Date.parse("1 september #{@year.year}").strftime("%Y-%m-%d")
        end
        respond_to do |format|
            format.json { render json: {
                "data": {
                    "name": name,
                    "dateValue": date,
                    "dateFormat": "yyyy-MM-dd"
                }
            } }
        end
    end

    def photograph
        hashdata = []
        unless @contest == false
            @contest.photos.where(year: @year).group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        else
            Photo.where(year: @year).group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        end
        nophoto = {
            "postfix": "Grafico delle foto caricate",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end

    def photoday
        hashdata = []
        unless @contest == false
            @contest.photos.where(year: @year).group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"date": pl[0].strftime("%Y-%m-%d"), "value": pl[1]})
            end
        else
            Photo.where(year: @year).group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"date": pl[0].strftime("%Y-%m-%d"), "value": pl[1]})
            end
        end
        nophoto = {
            "postfix": "Densità giornaliera delle foto caricate",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end

    def usedonwiki
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            photocount = @contestyear&.usedonwiki || 0
        else
            photocount = Photo.where(usedonwiki: true, year: @year).count
        end
        json = {
            'postfix': 'Fotografie usate sui progetti',
            'data': {
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def usedonwikipercentage
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            photocount = @contestyear&.usedonwiki_percentage&.truncate(1) || '0.0'
        else
            total_photos = @year.total
            used_photos = @year.photos.where(usedonwiki: true).count
            photocount = total_photos > 0 ? (used_photos.to_f / total_photos.to_f * 100.0).truncate(1) : '0.0'
        end
        json = {
            'postfix': 'Fotografie usate sui progetti',
            'data': {
                "value": photocount.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end


    def photos_relativetogeneral
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            contest_count = @contestyear&.count || 0
            total_count = @year.total || 1
            value = contest_count > 0 && total_count > 0 ? (contest_count.to_f / total_count.to_f * 100).truncate(1) : "0"
        else
            value = "100"
        end
        json = {
            'postfix': 'Fotografie in relazione al nazionale',
            'data': {
                "value": value.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def participants_relativetogeneral
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            contest_creators = @contestyear&.creators || 0
            total_creators = @year.creators || 1
            value = contest_creators > 0 && total_creators > 0 ? (contest_creators.to_f / total_creators.to_f * 100).truncate(1) : "0"
        else
            value = "100"
        end
        json = {
            'postfix': 'Partecipanti in relazione al nazionale',
            'data': {
                "value": value.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def special_photos
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            photocount = @contestyear&.special_category_count || 0
        else
            photocount = @year.special_category_total || 0
        end
        json = {
            'postfix': "#{@year.special_category_label || ENV["SPECIAL_CATEGORY_LABEL"]}",
            'data': {
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end

    end

    def new_monuments
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            photocount = @contestyear&.new_monuments || 0
        else
            photocount = @year.new_monuments || 0
        end
        json = {
            'postfix': "Nuovi monumenti",
            'data': {
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end

    end

    def iscrittiappostapercentage
        unless @contest == false
            @contestyear = ContestYear.find_by(contest: @contest, year: @year)
            creatorsapposta = @contestyear&.creatorsapposta&.to_f || 0
            creators = @contestyear&.creators&.to_f || 0
            photocount = creators > 0 ? (creatorsapposta / creators * 100.0).truncate(1) : '0.0'
        else
            total_creators = Creator.where(year: @year).count.to_f
            creatorsapposta = Creator.where.not(proveniencecontest: nil).where(year: @year).count.to_f
            photocount = total_creators > 0 ? (creatorsapposta / total_creators * 100.0).truncate(1) : '0.0'
        end
        json = {
            'postfix': 'Percentuale',
            'data': {
                "value": photocount.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def miglioriutenti
        unless @contest == false
            list = []
            @creators = []
            Creator.where(year: @year).each do |creator|
              if creator.photos.where(contest: @contest, year: @year).any?
                @creators.push(creator)
              end
            end
            @creators = @creators.sort_by{|gp| gp.photos.where(contest: @contest, year: @year).count}.reverse
            @creators.each do |creator|
                list.push({'name': creator.username, 'value': creator.photos.where(contest: @contest, year: @year).count})
            end
        else
            list = []
            @creators = Creator.where(year: @year).sort_by{|creator| creator.photos.where(year: @year).count}.reverse
            @creators.each do |creator|
                list.push({'name': creator.username, 'value': creator.photos.where(year: @year).count})
            end
        end
        json =  {
            "valueNameHeader": "Partecipanti più prolifici",
            "valueHeader": "Foto",
            "data": list
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def iscrittiappostagraph
        hashdata = []
        unless @contest == false
            Creator.where(proveniencecontest: @contest.id, year: @year).group_by_day(:creationdate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        else
            Creator.where.not(proveniencecontest: nil).where(year: @year).group_by_day(:creationdate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        end
        nophoto = {
            "postfix": "Grafico degli utenti iscritti per il concorso",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end
end
private
def set_contest
    if !params[:id].blank?
        @contest = Contest.find(params[:id])
    else
        @contest = false
    end
end

def set_year
    if params[:year].present? && (year = Year.find_by(year: params[:year]))
        @year = year
    elsif !cookies[:year_id].blank? && Year.find_by(id: cookies[:year_id].to_i)
        @year = Year.find(cookies[:year_id].to_i)
    elsif (@year = Year.find_by_year(Date.today.year))
        cookies[:year_id] = @year.id
    else
        @year = Year.last
    end
end
