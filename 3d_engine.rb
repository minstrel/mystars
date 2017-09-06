# encoding: utf-8

require 'matrix'

module Stars3D
  def translate(x,y,z)
    Matrix[
      [1,0,0,x],
      [0,1,0,y],
      [0,0,1,z],
      [0,0,0,1]
    ] 
  end
  def scale(x,y,z)
    Matrix.diagonal(x,y,z,1)
  end
  def rotate_x(theta)
    Matrix[
      [1, 0              , 0                   , 0],
      [0, Math.cos(theta), -1 * Math.sin(theta), 0],
      [0, Math.sin(theta), Math.cos(theta)     , 0],
      [0, 0              , 0                   , 1]  
    ] 
  end
  def rotate_y(theta)
    Matrix[
      [Math.cos(theta)      , 0, Math.sin(theta), 0],
      [0                    , 1, 0              , 0],
      [-1 * Math.sin(theta) , 0, Math.cos(theta), 0],
      [0                    , 0, 0              , 1]  
    ] 
  end
  def rotate_z(theta)
    Matrix[
      [Math.cos(theta), -1 * Math.sin(theta), 0, 0],
      [Math.sin(theta), Math.cos(theta)     , 0, 0],
      [0              , 0                   , 1, 0],
      [0              , 0                   , 0, 1]
    ] 
  end
  # Creates a view matrix based on camera position tx,ty,tz
  # And z axis rotated by rx,ry, rz
  def view(tx,ty,tz,rx,ry)
    self.translate(-tx,-ty,-tz) *
    self.rotate_z(-rz) *
    self.rotate_y(-ry) *
    self.rotate_x(-rx)
  end
end
