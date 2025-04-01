;; Payment Authorization Contract
;; This contract releases funds when documentation is complete

(define-data-var admin principal tx-sender)

;; Data structure for payment records
(define-map payment-records
  { payment-id: (string-ascii 64) }
  {
    shipment-id: (string-ascii 64),
    exporter-id: (string-ascii 32),
    importer-id: (string-ascii 32),
    amount: uint,
    currency: (string-ascii 10),
    status: (string-ascii 20),
    documents-verified: bool,
    customs-approved: bool,
    payment-released: bool,
    timestamp: uint
  }
)

;; Payment status constants
(define-constant STATUS_PENDING "PENDING")
(define-constant STATUS_APPROVED "APPROVED")
(define-constant STATUS_RELEASED "RELEASED")
(define-constant STATUS_REJECTED "REJECTED")

;; Public function to register a new payment
(define-public (register-payment
    (payment-id (string-ascii 64))
    (shipment-id (string-ascii 64))
    (exporter-id (string-ascii 32))
    (importer-id (string-ascii 32))
    (amount uint)
    (currency (string-ascii 10)))
  (begin
    (asserts! (is-none (map-get? payment-records { payment-id: payment-id })) (err u100))

    (map-set payment-records
      { payment-id: payment-id }
      {
        shipment-id: shipment-id,
        exporter-id: exporter-id,
        importer-id: importer-id,
        amount: amount,
        currency: currency,
        status: STATUS_PENDING,
        documents-verified: false,
        customs-approved: false,
        payment-released: false,
        timestamp: block-height
      }
    )
    (ok true)
  )
)

;; Public function to mark documents as verified
(define-public (mark-documents-verified (payment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? payment-records { payment-id: payment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set payment-records
      { payment-id: payment-id }
      (merge record { documents-verified: true })
    )
    (ok true)
  )
)

;; Public function to mark customs as approved
(define-public (mark-customs-approved (payment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? payment-records { payment-id: payment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set payment-records
      { payment-id: payment-id }
      (merge record { customs-approved: true })
    )
    (ok true)
  )
)

;; Public function to release payment
(define-public (release-payment (payment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? payment-records { payment-id: payment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (get documents-verified record) (err u101))
    (asserts! (get customs-approved record) (err u102))

    (map-set payment-records
      { payment-id: payment-id }
      (merge record {
        payment-released: true,
        status: STATUS_RELEASED
      })
    )
    (ok true)
  )
)

;; Public function to approve payment
(define-public (approve-payment (payment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? payment-records { payment-id: payment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set payment-records
      { payment-id: payment-id }
      (merge record { status: STATUS_APPROVED })
    )
    (ok true)
  )
)

;; Public function to reject payment
(define-public (reject-payment (payment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? payment-records { payment-id: payment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set payment-records
      { payment-id: payment-id }
      (merge record { status: STATUS_REJECTED })
    )
    (ok true)
  )
)

;; Read-only function to check payment status
(define-read-only (get-payment-status (payment-id (string-ascii 64)))
  (match (map-get? payment-records { payment-id: payment-id })
    record (ok (get status record))
    (err u404)
  )
)

;; Read-only function to get payment details
(define-read-only (get-payment-details (payment-id (string-ascii 64)))
  (map-get? payment-records { payment-id: payment-id })
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
