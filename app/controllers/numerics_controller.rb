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
            creatorcount = @year.creators_count || Photo.where(year: @year).distinct.count(:creator_id)
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
            creatorcount = @contestyear&.creatorsapposta&.to_i || @year.new_creators(contest: @contest).count
        else
            creatorcount = @year.year_analytic&.new_creators_count || @year.new_creators.count
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
        scope = @contest == false ? @year.new_creators : @year.new_creators(contest: @contest)
        photowithdate = scope.group_by_day(:creationdate).count.to_a.last(2).reverse
        photowithdate.each do |ph|
            data.push({'value': ph[1]})
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
            contest_count = @contestyear.count
            total_count = @year.total
            value = contest_count.try(:>, 0) && total_count.try(:>, 0) ? (contest_count.to_f / total_count.to_f * 100).truncate(1) : "0"
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
            contest_creators = @contestyear.creators
            total_creators = @year.creators_count
            value = contest_creators.try(:>, 0) && total_creators.try(:>, 0) ? (contest_creators.to_f / total_creators.to_f * 100).truncate(1) : "0"
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
            creatorsapposta = (@contestyear&.creatorsapposta || @year.new_creators(contest: @contest).count).to_f
            creators = (@contestyear&.creators || Photo.where(year: @year, contest: @contest).distinct.count(:creator_id)).to_f
            photocount = creators > 0 ? (creatorsapposta / creators * 100.0).truncate(1) : '0.0'
        else
            total_creators = (@year.creators_count || Photo.where(year: @year).distinct.count(:creator_id)).to_f
            creatorsapposta = (@year.year_analytic&.new_creators_count || @year.new_creators.count).to_f
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
        photo_scope = Photo.where(year: @year)
        photo_scope = photo_scope.where(contest: @contest) unless @contest == false

        rows = photo_scope
          .joins(:creator)
          .group("creators.id", "creators.username")
          .order(Arel.sql("COUNT(photos.id) DESC"))
          .pluck("creators.username", Arel.sql("COUNT(photos.id)"))

        list = rows.map { |username, count| { 'name': username, 'value': count } }
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
        scope = @contest == false ? @year.new_creators : @year.new_creators(contest: @contest)
        scope.group_by_day(:creationdate).count.to_a.last(31).each do |pl|
            hashdata.push({"value": pl[1]})
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
    if params[:year].present? && (year = Year.find_by(year: params[:year].to_s))
        @year = year
    elsif (@year = Year.find_by(year: Date.today.year.to_s))
        @year
    else
        @year = Year.order(:year).last
    end
end
