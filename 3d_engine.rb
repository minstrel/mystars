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
  # Actually this -applies- the view matrix to an object - this was done for
  # testing, clean this up to just make the matrix.
  def view(tx,ty,tz,rx,ry,rz)
    self.rotate_x(-rx) *
    self.rotate_y(-ry) *
    self.rotate_z(-rz) *
    self.translate(-tx,-ty,-tz)
  end
  # Perspective projection matrix based on field of view in radians fw and fh
  # and near and far clipping panes zn and zf
  def projection(fw, fh, zn, zf)
    w = 1 / Math.tan(fw/2)
    h = 1 / Math.tan(fh/2)
    q = zf / (zf - zn)
    Matrix[
      [w, 0, 0, 0      ],
      [0, h, 0, 0      ],
      [0, 0, q, -q * zn],
      [0, 0, 1, 0      ]
    ]
  end
end
