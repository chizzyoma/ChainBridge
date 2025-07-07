;; ChainBridge NFT Hub - Condensed Version
;; All original functionalities preserved

;; Constants
(define-constant PLATFORM_OWNER tx-sender)
(define-constant PLATFORM_FEE_PERCENTAGE u5)
(define-constant REFERRAL_BONUS_PERCENTAGE u1)

;; Errors
(define-constant ERR_UNAUTHORIZED_ACCESS (err u1))
(define-constant ERR_INSUFFICIENT_FUNDS (err u2))
(define-constant ERR_INVALID_ROYALTY_RATE (err u3))
(define-constant ERR_TOKEN_NOT_EXISTS (err u4))
(define-constant ERR_INVALID_TOKEN_ID (err u5))
(define-constant ERR_INVALID_PRICE_VALUE (err u6))
(define-constant ERR_ITEM_ALREADY_LISTED (err u7))
(define-constant ERR_UNSUPPORTED_BLOCKCHAIN (err u8))
(define-constant ERR_INVALID_METADATA_FORMAT (err u9))
(define-constant ERR_ITEM_NOT_LISTED (err u10))
(define-constant ERR_INVALID_EXTERNAL_TOKEN_ID (err u11))
(define-constant ERR_USER_RESTRICTED (err u12))
(define-constant ERR_INVALID_REFERRER (err u13))
(define-constant ERR_CANNOT_RESTRICT_OWNER (err u14))
(define-constant ERR_USER_NOT_RESTRICTED (err u15))
(define-constant ERR_INVALID_USER_ADDRESS (err u16))

;; NFT Token
(define-non-fungible-token chainbridge-nft uint)

;; Data Maps
(define-map creator-royalty-registry { token-id: uint } { original-creator: principal, royalty-percentage: uint })
(define-map marketplace-listings { token-id: uint } { asking-price: uint, current-seller: principal, is-active: bool })
(define-map blockchain-token-registry { blockchain-name: (string-ascii 20), external-token-id: (string-ascii 50) } { internal-token-id: uint })
(define-map token-metadata-registry { token-id: uint } { display-name: (string-ascii 100), description-text: (string-ascii 500), image-uri: (string-ascii 200), trait-attributes: (list 20 {property: (string-ascii 50), property-value: (string-ascii 50)}) })
(define-map transaction-history-log { token-id: uint } (list 50 { previous-owner: principal, new-owner: principal, sale-price: uint }))
(define-map user-restriction-list { user-address: principal } { is-restricted: bool })
(define-map user-referral-connections { referred-user: principal } { referring-user: principal })
(define-map referral-earnings-ledger { referrer-address: principal } { accumulated-rewards: uint })

;; Analytics Variables
(define-data-var platform-total-volume uint u0)
(define-data-var platform-total-royalties uint u0)
(define-data-var platform-total-fees uint u0)

;; Validation Helpers
(define-private (verify-token-ownership (token-id uint))
  (match (nft-get-owner? chainbridge-nft token-id) owner (is-eq tx-sender owner) false))

(define-private (validate-blockchain-network (blockchain-name (string-ascii 20)))
  (or (is-eq blockchain-name "ethereum") (is-eq blockchain-name "solana") (is-eq blockchain-name "polygon") (is-eq blockchain-name "binance")))

(define-private (validate-token-id-range (token-id uint))
  (and (> token-id u0) (< token-id u10000000)))

(define-private (validate-metadata-structure (metadata-info (tuple (display-name (string-ascii 100)) (description-text (string-ascii 500)) (image-uri (string-ascii 200)) (trait-attributes (list 20 (tuple (property (string-ascii 50)) (property-value (string-ascii 50))))))))
  (and (> (len (get display-name metadata-info)) u0) (> (len (get description-text metadata-info)) u0) (> (len (get image-uri metadata-info)) u0)))

(define-private (validate-external-token-id (external-token-id (string-ascii 50)))
  (and (> (len external-token-id) u0) (<= (len external-token-id) u50)))

(define-private (check-user-restriction-status (user-address principal))
  (default-to false (get is-restricted (map-get? user-restriction-list { user-address: user-address }))))

(define-private (validate-user-address (user-address principal))
  (not (is-eq user-address PLATFORM_OWNER)))

;; Core Functions

;; Mint NFT
(define-public (create-new-nft (token-id uint) (creator-royalty-rate uint) (metadata-info (tuple (display-name (string-ascii 100)) (description-text (string-ascii 500)) (image-uri (string-ascii 200)) (trait-attributes (list 20 (tuple (property (string-ascii 50)) (property-value (string-ascii 50))))))))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (<= creator-royalty-rate u25) ERR_INVALID_ROYALTY_RATE)
    (asserts! (validate-metadata-structure metadata-info) ERR_INVALID_METADATA_FORMAT)
    (try! (nft-mint? chainbridge-nft token-id tx-sender))
    (map-set creator-royalty-registry { token-id: token-id } { original-creator: tx-sender, royalty-percentage: creator-royalty-rate })
    (map-set token-metadata-registry { token-id: token-id } metadata-info)
    (ok token-id)))

;; Batch Mint
(define-public (create-multiple-nfts (token-id-list (list 20 uint)) (royalty-rate-list (list 20 uint)) (metadata-info-list (list 20 (tuple (display-name (string-ascii 100)) (description-text (string-ascii 500)) (image-uri (string-ascii 200)) (trait-attributes (list 20 (tuple (property (string-ascii 50)) (property-value (string-ascii 50)))))))))
  (begin
    (asserts! (is-eq (len token-id-list) (len royalty-rate-list)) ERR_INVALID_TOKEN_ID)
    (asserts! (is-eq (len token-id-list) (len metadata-info-list)) ERR_INVALID_TOKEN_ID)
    (ok (map create-new-nft token-id-list royalty-rate-list metadata-info-list))))

;; List for Sale
(define-public (list-token-for-sale (token-id uint) (asking-price uint))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (verify-token-ownership token-id) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (> asking-price u0) ERR_INVALID_PRICE_VALUE)
    (match (map-get? marketplace-listings { token-id: token-id })
      existing-listing (asserts! (not (get is-active existing-listing)) ERR_ITEM_ALREADY_LISTED)
      true)
    (map-set marketplace-listings { token-id: token-id } { asking-price: asking-price, current-seller: tx-sender, is-active: true })
    (ok true)))

;; Batch List
(define-public (list-multiple-tokens-for-sale (token-id-list (list 20 uint)) (price-list (list 20 uint)))
  (begin
    (asserts! (is-eq (len token-id-list) (len price-list)) ERR_INVALID_TOKEN_ID)
    (ok (map list-token-for-sale token-id-list price-list))))

;; Remove Listing
(define-public (remove-token-listing (token-id uint))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (verify-token-ownership token-id) ERR_UNAUTHORIZED_ACCESS)
    (match (map-get? marketplace-listings { token-id: token-id })
      existing-listing (if (get is-active existing-listing)
        (begin (map-set marketplace-listings { token-id: token-id } { asking-price: u0, current-seller: tx-sender, is-active: false }) (ok true))
        ERR_ITEM_NOT_LISTED)
      ERR_TOKEN_NOT_EXISTS)))

;; Purchase NFT
(define-public (purchase-listed-nft (token-id uint) (referrer-address (optional principal)))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (not (check-user-restriction-status tx-sender)) ERR_USER_RESTRICTED)
    (match (nft-get-owner? chainbridge-nft token-id) current-token-owner
      (match (map-get? marketplace-listings { token-id: token-id }) listing-details
        (match (map-get? creator-royalty-registry { token-id: token-id }) royalty-details
          (begin
            (asserts! (get is-active listing-details) ERR_ITEM_NOT_LISTED)
            (asserts! (>= (stx-get-balance tx-sender) (get asking-price listing-details)) ERR_INSUFFICIENT_FUNDS)
            (let ((price (get asking-price listing-details))
                  (platform-fee (/ (* price PLATFORM_FEE_PERCENTAGE) u100))
                  (royalty-fee (/ (* price (get royalty-percentage royalty-details)) u100))
                  (referral-fee (/ (* price REFERRAL_BONUS_PERCENTAGE) u100)))
              (try! (stx-transfer? platform-fee tx-sender PLATFORM_OWNER))
              (try! (stx-transfer? royalty-fee tx-sender (get original-creator royalty-details)))
              (match referrer-address referrer-principal
                (begin
                  (asserts! (not (is-eq referrer-principal tx-sender)) ERR_INVALID_REFERRER)
                  (try! (stx-transfer? referral-fee tx-sender referrer-principal))
                  (map-set user-referral-connections { referred-user: tx-sender } { referring-user: referrer-principal })
                  (map-set referral-earnings-ledger { referrer-address: referrer-principal }
                    { accumulated-rewards: (+ (default-to u0 (get accumulated-rewards (map-get? referral-earnings-ledger { referrer-address: referrer-principal }))) referral-fee) }))
                true)
              (try! (stx-transfer? (- price (+ platform-fee royalty-fee referral-fee)) tx-sender current-token-owner))
              (try! (nft-transfer? chainbridge-nft token-id current-token-owner tx-sender))
              (map-set marketplace-listings { token-id: token-id } { asking-price: u0, current-seller: tx-sender, is-active: false })
              (var-set platform-total-volume (+ (var-get platform-total-volume) price))
              (var-set platform-total-royalties (+ (var-get platform-total-royalties) royalty-fee))
              (var-set platform-total-fees (+ (var-get platform-total-fees) platform-fee))
              (ok true)))
          ERR_TOKEN_NOT_EXISTS)
        ERR_TOKEN_NOT_EXISTS)
      ERR_TOKEN_NOT_EXISTS)))

;; Cross-Chain Bridge
(define-public (bridge-external-nft (blockchain-name (string-ascii 20)) (external-token-id (string-ascii 50)) (internal-token-id uint) (metadata-info (tuple (display-name (string-ascii 100)) (description-text (string-ascii 500)) (image-uri (string-ascii 200)) (trait-attributes (list 20 (tuple (property (string-ascii 50)) (property-value (string-ascii 50))))))))
  (begin
    (asserts! (validate-blockchain-network blockchain-name) ERR_UNSUPPORTED_BLOCKCHAIN)
    (asserts! (validate-external-token-id external-token-id) ERR_INVALID_EXTERNAL_TOKEN_ID)
    (asserts! (validate-token-id-range internal-token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (validate-metadata-structure metadata-info) ERR_INVALID_METADATA_FORMAT)
    (try! (nft-mint? chainbridge-nft internal-token-id tx-sender))
    (map-set blockchain-token-registry { blockchain-name: blockchain-name, external-token-id: external-token-id } { internal-token-id: internal-token-id })
    (map-set token-metadata-registry { token-id: internal-token-id } metadata-info)
    (ok internal-token-id)))

;; Update Metadata
(define-public (update-token-metadata (token-id uint) (updated-metadata (tuple (display-name (string-ascii 100)) (description-text (string-ascii 500)) (image-uri (string-ascii 200)) (trait-attributes (list 20 (tuple (property (string-ascii 50)) (property-value (string-ascii 50))))))))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (verify-token-ownership token-id) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (validate-metadata-structure updated-metadata) ERR_INVALID_METADATA_FORMAT)
    (map-set token-metadata-registry { token-id: token-id } updated-metadata)
    (ok true)))

;; User Restriction Management
(define-public (add-user-to-restriction-list (target-address principal))
  (begin
    (asserts! (is-eq tx-sender PLATFORM_OWNER) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (not (is-eq target-address PLATFORM_OWNER)) ERR_CANNOT_RESTRICT_OWNER)
    (ok (map-set user-restriction-list { user-address: target-address } { is-restricted: true }))))

(define-public (remove-user-from-restriction-list (target-address principal))
  (begin
    (asserts! (is-eq tx-sender PLATFORM_OWNER) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (validate-user-address target-address) ERR_INVALID_USER_ADDRESS)
    (match (map-get? user-restriction-list { user-address: target-address }) restriction-entry
      (begin
        (asserts! (get is-restricted restriction-entry) ERR_USER_NOT_RESTRICTED)
        (ok (map-delete user-restriction-list { user-address: target-address })))
      ERR_USER_NOT_RESTRICTED)))

;; Read-Only Functions
(define-read-only (get-token-metadata (token-id uint))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (ok (map-get? token-metadata-registry { token-id: token-id }))))

(define-read-only (get-complete-token-info (token-id uint))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (ok {
      current-owner: (nft-get-owner? chainbridge-nft token-id),
      marketplace-listing: (map-get? marketplace-listings { token-id: token-id }),
      royalty-info: (map-get? creator-royalty-registry { token-id: token-id }),
      metadata-info: (map-get? token-metadata-registry { token-id: token-id })
    })))

(define-read-only (get-token-transaction-history (token-id uint))
  (begin
    (asserts! (validate-token-id-range token-id) ERR_INVALID_TOKEN_ID)
    (ok (map-get? transaction-history-log { token-id: token-id }))))

(define-read-only (get-platform-analytics)
  (ok {
    total-trading-volume: (var-get platform-total-volume),
    total-royalty-payments: (var-get platform-total-royalties),
    total-platform-fees: (var-get platform-total-fees)
  }))

(define-read-only (get-user-referral-data (user-address principal))
  (ok {
    referring-user: (get referring-user (map-get? user-referral-connections { referred-user: user-address })),
    total-referral-earnings: (get accumulated-rewards (map-get? referral-earnings-ledger { referrer-address: user-address }))
  }))