module Project where

import qualified ERC20
import           YolSuite.YOLC.Manifest

manifest :: Manifest
manifest = MkManifest
  { buildUnits = [ MkBuildUnit { mainObject = ERC20.object
                               , deploymentType = SingletonContract
                               , upgradabilityMode = NonUpgradable
                               }
                 ]
  }
