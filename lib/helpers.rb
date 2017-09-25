# encoding: utf-8

# Helper / monkey patch methods

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def to_deg
    self * ( 180 / Math::PI )
  end
  def long_to_ra
    if self < 0
      (self + 360) / 15
    else
      self / 15
    end
  end
end
