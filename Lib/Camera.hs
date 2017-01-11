module Camera where

import Math
import Linear
import Linear.Affine

newtype UnitSpace = US (V2 Float)

newtype Sensor = Sensor (Int, Int, V2 Float, Float)    -- width, height, physical size, exposure

-- |Interface for all cameras with two needed functions
class Camera cam where
    cameraRay    :: cam -> UnitSpace -> RaySegment
    cameraSensor :: cam -> Sensor

-- |Our cameras
data PinholeCamera = PinholeCamera {
            phcamSensor      :: Sensor,
            phcamPos         :: Coord3,
            phcamDir         :: UnitV3,
            phcamUp          :: UnitV3,
            phcamFocalLength :: Float }

data OrthoCamera = OrthoCamera {
            orthoSensor      :: Sensor,
            orthoPos         :: Coord3,
            orthoDir         :: UnitV3,
            orthoUp          :: UnitV3 }

-- |Implementation of Ortho camera
instance Camera OrthoCamera where
      cameraRay cam (US imagePos) = RaySeg (Ray (start, orthoDir cam), farthestDistance) where
          Sensor (_,_,sensorSize,_)  = orthoSensor cam
          aspect        = sensorAspect.orthoSensor $ cam

          (V2 x y)      = (imagePos - V2 0.5 0.5) * sensorSize
          vpos3         = V3 (x*aspect) y 0.0
          start         = orthoPos cam .+^ (vpos3 *! view)

          xaxis         = normalize( cross (normalized.orthoUp $ cam) zaxis )
          yaxis         = cross zaxis xaxis
          zaxis         = normalized( orthoDir cam )

          view          = V3 xaxis yaxis zaxis                  :: M33 Float

      cameraSensor = orthoSensor

-- |Implementation of Pinhole camera
instance Camera PinholeCamera where
    cameraRay cam (US imagePos) = RaySeg (Ray (phcamPos cam, normalize3 proj), farthestDistance) where
        Sensor (_,_,sensorSize,_) = phcamSensor cam
        aspect   = sensorAspect.phcamSensor $ cam

        (V2 x y) = (imagePos - V2 0.5 0.5) * sensorSize
        vpos3    = V3 (x*aspect) (-y) 0.0

        d        = normalized( phcamDir cam )
        v        = d ^* phcamFocalLength cam - vpos3
        proj     = v *! view

        xaxis    = normalize( cross( normalized.phcamUp $ cam ) zaxis )
        yaxis    = cross zaxis xaxis
        zaxis    = normalized( phcamDir cam )

        view     = V3 xaxis yaxis zaxis

    cameraSensor = phcamSensor


-----------------------------------------------------------------------------------------------------------------------
sensorAspect :: Sensor -> Float
sensorAspect (Sensor (w,h,V2 sw sy,_)) =
    fromIntegral w / fromIntegral h / sizeAspect where
        sizeAspect = sw/sy

toScreenSpace :: Sensor -> Int -> Int -> UnitSpace
toScreenSpace (Sensor (width, height, _, _)) x y = US $ V2 sx sy where
        sx = fromIntegral x / (fromIntegral width  - 1)
        sy = fromIntegral y / (fromIntegral height - 1)