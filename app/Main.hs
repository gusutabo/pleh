module Main (main) where

import Logic

main :: IO ()
main = mapM_ print (truthTable formula)
