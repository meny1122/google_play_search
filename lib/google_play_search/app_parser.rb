require File.expand_path(File.dirname(__FILE__) + '/app')
require File.expand_path(File.dirname(__FILE__) + '/utils')

module GooglePlaySearch
  class AppParser
    include GooglePlaySearch::Utils

    SEARCH_APP_URL_END_SUFF = "&feature=search_result"

    def initialize(content)
      @doc = Nokogiri::HTML(content)
    end
    def parse
      app_search_result_list = []
      if @doc.css("div.card-list div.card").size > 0
        @doc.css("div.card-list div.card").each do |app_content|
          app_search_result_list << create_app(app_content)
        end
      else
        @doc.css("li.z-last-child div.snippet").each do |app_content|
          app_search_result_list << create_app(app_content)
        end
      end
      app_search_result_list
    end

    private
    def get_url(app_content)
      url = $GOOGLE_PLAY_STORE_BASE_URL + app_content.css("a.card-click-target").first['href']
      if url.end_with?(SEARCH_APP_URL_END_SUFF)
        url = url[0..-1* (SEARCH_APP_URL_END_SUFF.size + 1)]
      end
      url
    end

    def get_logo_url(app_content)
      add_http_prefix(app_content.css("img.cover-image").first['src'])
    end

    def get_name(app_content)
      app_content.css("a.title").first.content.strip
    end

    def get_developer(app_content)
      developer_contents_list = app_content.css("div.subtitle-container a.subtitle")
      if developer_contents_list && developer_contents_list.size > 0
        return developer_contents_list.first.content
      else
        developer_contents_single = app_content.css("div.details span.attribution a")
        if developer_contents_single && developer_contents_single.size > 0
          return developer_contents_single.first.content
        end
      end
      return ""
    end

    def get_category(app_content)
      category_contents = app_content.css("div.attribution-category span.category a")
      if category_contents && category_contents.size>0
        return category_contents.first.content
      end
      return ""
    end

    def get_short_description(app_content)
      description_contents = app_content.css("div.description")
      if description_contents && description_contents.size > 0
        return description_contents.first.content.strip
      end
      return ""
    end

    def get_app_rating(app_content)
      ratings = app_content.css("div.current-rating")
      if ratings && ratings.first
        rating_str = ratings.first['style']
        unless rating_str.empty?
          return rating_str[/\d+\.?\d?/].to_f / 100 * 5
        end
        return 0
      end
    end

    def get_app_price(app_content)
      prices = app_content.css("span.price-container button.price span")
      if prices and prices.first
        if match = prices.first.content.match(/(.[0-9]*\.[0-9]+|[0-9]+)/)
          return '¥' + match[1]
        end
      end
      return "無料"
    end

    def create_app(app_content)
      app = App.new
      app.url = get_url app_content
      app.id = app.url[app.url.index("?id=")+4..-1]
      app.name = get_name app_content
      app.price = get_app_price app_content
      app.developer = get_developer app_content
      app.logo_url = get_logo_url app_content
      app.short_description = get_short_description app_content
      app.rating = get_app_rating app_content
      return app
    end
  end
end
