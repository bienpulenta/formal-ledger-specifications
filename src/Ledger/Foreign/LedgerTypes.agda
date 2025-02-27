module Ledger.Foreign.LedgerTypes where

open import Prelude

open import Foreign.Haskell
open import Foreign.Haskell.Coerce

data Empty : Set where

{-# FOREIGN GHC data AgdaEmpty #-}
{-# COMPILE GHC Empty = data AgdaEmpty () #-}

HSMap : Set → Set → Set
HSMap K V = List (Pair K V)

Coin          = ℕ
Addr          = ℕ -- just payment credential

TxId          = ℕ
Ix            = ℕ
Epoch         = ℕ
AuxiliaryData = ⊤
Network       = ⊤

TxIn          = Pair TxId Ix
TxOut         = Pair Addr Coin
UTxO          = HSMap TxIn TxOut

{-# FOREIGN GHC
  type Coin  = Integer
  type Addr  = Integer

  type TxId  = Integer
  type Ix    = Integer
  type TxIn  = (TxId, Ix)
  type TxOut = (Addr, Coin)
  type UTxO  = [(TxIn, TxOut)]
#-}

record TxBody : Set where
  field txins    : List TxIn
        txouts   : HSMap Ix TxOut
        txfee    : Coin
        txvldt   : Pair (Maybe ℕ) (Maybe ℕ)
        --txwdrls  : Wdrl
        --txup     : Maybe Update
        --txADhash : Maybe ADHash
        txsize   : ℕ
        txid     : TxId

{-# FOREIGN GHC
  data TxBody = MkTxBody
    { txins  :: [TxIn]
    , txouts :: [(Ix, TxOut)]
    , txfee  :: Coin
    , txvldt :: (Maybe Integer, Maybe Integer)
    , txsize :: Integer
    , txid   :: TxId } deriving Show
#-}
{-# COMPILE GHC TxBody = data TxBody (MkTxBody) #-}

record TxWitnesses : Set where
  field vkSigs  : List (Pair ℕ ℕ)
        scripts : List Empty

{-# FOREIGN GHC data TxWitnesses = MkTxWitnesses { vkSigs :: [(Integer, Integer)], scripts :: [AgdaEmpty] } #-}
{-# COMPILE GHC TxWitnesses = data TxWitnesses (MkTxWitnesses) #-}

record Tx : Set where
  field body : TxBody
        wits : TxWitnesses
        txAD : Maybe ⊤

{-# FOREIGN GHC data Tx = MkTx { body :: TxBody, wits :: TxWitnesses, txAD :: Maybe () } #-}
{-# COMPILE GHC Tx = data Tx (MkTx) #-}

record PParams : Set where
  field a             : ℕ
        b             : ℕ
        maxBlockSize  : ℕ
        maxTxSize     : ℕ
        maxHeaderSize : ℕ
        maxValSize    : ℕ
        minUtxOValue  : Coin
        poolDeposit   : Coin
        Emax          : Epoch
        pv            : Pair ℕ ℕ

{-# FOREIGN GHC
  data PParams = MkPParams
    { a :: Integer
    , b :: Integer
    , maxBlockSize :: Integer
    , maxTxSize :: Integer
    , maxHeaderSize :: Integer
    , maxValSize :: Integer
    , minUtxOValue :: Integer
    , poolDeposit :: Integer
    , emax :: Integer
    , pv :: (Integer, Integer) } deriving Show
#-}
{-# COMPILE GHC PParams = data PParams (MkPParams) #-}

record UTxOEnv : Set where
  field slot    : ℕ
        pparams : PParams

{-# FOREIGN GHC data UTxOEnv = MkUTxOEnv { slot :: Integer, pparams :: PParams } deriving Show #-}
{-# COMPILE GHC UTxOEnv = data UTxOEnv (MkUTxOEnv) #-}

record UTxOState : Set where
  field utxo : UTxO
        fees : Coin

{-# FOREIGN GHC data UTxOState = MkUTxOState { utxo :: UTxO, fees :: Coin } deriving Show #-}
{-# COMPILE GHC UTxOState = data UTxOState (MkUTxOState) #-}
