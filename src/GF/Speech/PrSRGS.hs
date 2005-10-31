----------------------------------------------------------------------
-- |
-- Module      : PrSRGS
-- Maintainer  : BB
-- Stability   : (stable)
-- Portability : (portable)
--
-- > CVS $Date: 2005/10/31 16:48:08 $ 
-- > CVS $Author: bringert $
-- > CVS $Revision: 1.1 $
--
-- This module prints a CFG as an SRGS XML grammar.
--
-- FIXME: remove \/ warn \/ fail if there are int \/ string literal
-- categories in the grammar
-----------------------------------------------------------------------------

module GF.Speech.PrSRGS (srgsXmlPrinter) where

import GF.Data.Utilities
import GF.Speech.SRG
import GF.Infra.Ident

import GF.Formalism.CFG
import GF.Formalism.Utilities (Symbol(..))
import GF.Conversion.Types
import GF.Infra.Print
import GF.Infra.Option

import Data.Char (toUpper,toLower)

data XML = Data String | Tag String [Attr] [XML] | Comment String
 deriving (Eq,Show)

type Attr = (String,String)

srgsXmlPrinter :: Ident -- ^ Grammar name
	   -> Options -> CGrammar -> String
srgsXmlPrinter name opts cfg = prSrgsXml srg ""
    where srg = makeSRG name opts cfg

prSrgsXml :: SRG -> ShowS
prSrgsXml (SRG{grammarName=name,startCat=start,origStartCat=origStart,rules=rs})
    = header . showsXML xmlGr
    where
    header = showString "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
    root = prCat start
    xmlGr = grammar root (comments 
			  ["SRGS XML speech recognition grammar for " ++ name,
			   "Generated by GF",
			   "Original start category: " ++ origStart]
			  ++ map ruleToXML rs)
    ruleToXML (SRGRule cat origCat rhss) = 
	rule (prCat cat) (comments ["Category " ++ origCat] ++ [prRhs rhss])
    prRhs rhss = oneOf (map item (map prAlt rhss))
    -- FIXME: don't use one-of if there is only one
    prAlt rhs = map prSymbol rhs
    prSymbol (Cat c) = Tag "ruleref" [("uri","#" ++ prCat c)] []
    prSymbol (Tok t) = item [Data (showToken t)]
    prCat c = c -- FIXME: escape something?
    showToken t = t -- FIXME: escape something?

rule :: String -- ^ id
     -> [XML] -> XML
rule i = Tag "rule" [("id",i)]

item :: [XML] -> XML
item [x@(Tag "item" _ _)] = x
item xs = Tag "item" [] xs

oneOf :: [XML] -> XML
oneOf [x] = x
oneOf xs = Tag "one-of" [] xs

-- FIXME: what about xml:lang?
grammar :: String  -- ^ root
	-> [XML] -> XML
grammar root = Tag "grammar" [("xmlns","http://www.w3.org/2001/06/grammar"),
			      ("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance"),
			      ("xsi:schemaLocation",
			       "http://www.w3.org/2001/06/grammar http://www.w3.org/TR/speech-grammar/grammar.xsd"),
			      ("version","1.0"),
			      ("mode","voice"),
			      ("root",root)]

comments :: [String] -> [XML]
comments = map Comment

showsXML :: XML -> ShowS
showsXML (Data s) = showString s
showsXML (Tag t as []) = showChar '<' . showString t . showsAttrs as . showString "/>"
showsXML (Tag t as cs) = 
    showChar '<' . showString t . showsAttrs as . showChar '>' 
		 . concatS (map showsXML cs) . showString "</" . showString t . showChar '>'
showsXML (Comment c) = showString "<!-- " . showString c . showString " -->"

showsAttrs :: [Attr] -> ShowS
showsAttrs = concatS . map (showChar ' ' .) . map showsAttr

showsAttr :: Attr -> ShowS
showsAttr (n,v) = showString n . showString "=\"" . showString (escape v) . showString "\""

-- FIXME: escape double quotes
escape :: String -> String
escape = id