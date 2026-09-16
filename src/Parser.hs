module Parser
  ( parseFormula
  ) where

import Data.Char (isAlpha, isAlphaNum, isSpace)
import Data.List (stripPrefix)

import Logic (Formula (..))

data Token
  = TVar String
  | TNot
  | TAnd
  | TOr
  | TImp
  | TIff
  | TOpen
  | TClose
  deriving (Show, Eq)

parseFormula :: String -> Either String Formula
parseFormula input = do
  tokens <- tokenize input
  (f, rest) <- pIff tokens
  case rest of
    [] -> Right f
    (t : _) -> Left ("Unexpected " ++ describe t ++ " after a complete formula")

symbols :: [(String, Token)]
symbols =
  [ ("<->", TIff)
  , ("<=>", TIff)
  , ("\8596", TIff)
  , ("->", TImp)
  , ("=>", TImp)
  , ("\8594", TImp)
  , ("/\\", TAnd)
  , ("&&", TAnd)
  , ("&", TAnd)
  , ("\8743", TAnd)
  , ("\\/", TOr)
  , ("||", TOr)
  , ("|", TOr)
  , ("\8744", TOr)
  , ("~", TNot)
  , ("!", TNot)
  , ("\172", TNot)
  , ("(", TOpen)
  , (")", TClose)
  ]

keywords :: [(String, Token)]
keywords =
  [ ("not", TNot)
  , ("and", TAnd)
  , ("or", TOr)
  , ("implies", TImp)
  , ("iff", TIff)
  ]

tokenize :: String -> Either String [Token]
tokenize [] = Right []
tokenize s@(c : cs)
  | isSpace c = tokenize cs
  | Just (t, rest) <- symbol s = (t :) <$> tokenize rest
  | isAlpha c =
      let (name, rest) = span isIdentChar s
       in (maybe (TVar name) id (lookup name keywords) :) <$> tokenize rest
  | otherwise = Left ("Unexpected character " ++ show c)
  where
    isIdentChar ch = isAlphaNum ch || ch == '_' || ch == '\''

symbol :: String -> Maybe (Token, String)
symbol s =
  case [(t, rest) | (sym, t) <- symbols, Just rest <- [stripPrefix sym s]] of
    (m : _) -> Just m
    [] -> Nothing

describe :: Token -> String
describe (TVar x) = "variable " ++ show x
describe TNot = "'not'"
describe TAnd = "'and'"
describe TOr = "'or'"
describe TImp = "'implies'"
describe TIff = "'iff'"
describe TOpen = "'('"
describe TClose = "')'"

--   iff  := imp ('<->' iff)?     -- right associative, loosest
--   imp  := or ('->' imp)?       -- right associative
--   or   := and ('|' and)*       -- left associative
--   and  := neg ('&' neg)*       -- left associative
--   neg  := '~' neg | atom
--   atom := variable | '(' iff ')'

type Parser = [Token] -> Either String (Formula, [Token])

pIff :: Parser
pIff = rightAssoc TIff Iff pImp

pImp :: Parser
pImp = rightAssoc TImp Imp pOr

pOr :: Parser
pOr = leftAssoc TOr Or pAnd

pAnd :: Parser
pAnd = leftAssoc TAnd And pNeg

pNeg :: Parser
pNeg (TNot : ts) = do
  (f, rest) <- pNeg ts
  Right (Not f, rest)
pNeg ts = pAtom ts

pAtom :: Parser
pAtom (TVar x : ts) = Right (Var x, ts)
pAtom (TOpen : ts) = do
  (f, rest) <- pIff ts
  case rest of
    (TClose : rest') -> Right (f, rest')
    (t : _) -> Left ("Expected ')' but found " ++ describe t)
    [] -> Left "Expected ')' but reached the end of the input"
pAtom (t : _) = Left ("Expected a variable or '(' but found " ++ describe t)
pAtom [] = Left "Expected a variable or '(' but reached the end of the input"

rightAssoc :: Token -> (Formula -> Formula -> Formula) -> Parser -> Parser
rightAssoc tok con next ts = do
  (l, rest) <- next ts
  case rest of
    (t : rest') | t == tok -> do
      (r, rest'') <- rightAssoc tok con next rest'
      Right (con l r, rest'')
    _ -> Right (l, rest)

leftAssoc :: Token -> (Formula -> Formula -> Formula) -> Parser -> Parser
leftAssoc tok con next ts = do
  (l, rest) <- next ts
  go l rest
  where
    go acc (t : rest) | t == tok = do
      (r, rest') <- next rest
      go (con acc r) rest'
    go acc rest = Right (acc, rest)
