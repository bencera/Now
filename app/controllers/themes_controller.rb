class ThemesController < ApplicationController
  def index
    @themes = Theme.index(:all => true)
  end
end
