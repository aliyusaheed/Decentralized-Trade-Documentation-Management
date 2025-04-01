;; Exporter Verification Contract
;; This contract validates seller credentials and history

(define-data-var admin principal tx-sender)

;; Data structure for exporters
(define-map exporters
  { exporter-id: (string-ascii 32) }
  {
    principal: principal,
    name: (string-ascii 100),
    country: (string-ascii 50),
    registration-number: (string-ascii 50),
    verified: bool,
    rating: uint,
    total-transactions: uint
  }
)

;; Public function to register a new exporter
(define-public (register-exporter
    (exporter-id (string-ascii 32))
    (name (string-ascii 100))
    (country (string-ascii 50))
    (registration-number (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? exporters { exporter-id: exporter-id })) (err u100))

    (map-set exporters
      { exporter-id: exporter-id }
      {
        principal: tx-sender,
        name: name,
        country: country,
        registration-number: registration-number,
        verified: false,
        rating: u0,
        total-transactions: u0
      }
    )
    (ok true)
  )
)

;; Public function to verify an exporter
(define-public (verify-exporter (exporter-id (string-ascii 32)))
  (let ((exporter (unwrap! (map-get? exporters { exporter-id: exporter-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set exporters
      { exporter-id: exporter-id }
      (merge exporter { verified: true })
    )
    (ok true)
  )
)

;; Public function to update exporter rating after transaction
(define-public (update-exporter-rating
    (exporter-id (string-ascii 32))
    (new-rating uint))
  (let ((exporter (unwrap! (map-get? exporters { exporter-id: exporter-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= new-rating u5) (err u101))

    (map-set exporters
      { exporter-id: exporter-id }
      (merge exporter {
        rating: new-rating,
        total-transactions: (+ (get total-transactions exporter) u1)
      })
    )
    (ok true)
  )
)

;; Read-only function to check if an exporter is verified
(define-read-only (is-verified (exporter-id (string-ascii 32)))
  (match (map-get? exporters { exporter-id: exporter-id })
    exporter (ok (get verified exporter))
    (err u404)
  )
)

;; Read-only function to get exporter details
(define-read-only (get-exporter-details (exporter-id (string-ascii 32)))
  (map-get? exporters { exporter-id: exporter-id })
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
