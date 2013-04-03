class ThemesController < ApplicationController
  def index
    @themes = Theme.index
  end
end
